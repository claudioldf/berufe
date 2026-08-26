# frozen_string_literal: true

module Admin
  module Reports
    class GrowthReport
      PRIVACY_NOTICE = "Dados agregados, sem identidade de visitante, nomes de clientes de orçamentos ou conteúdo de conversas no WhatsApp."
      MILESTONES = {
        published: [5, 10, 20, 30, 50],
        activated: [3, 5, 8, 10, 20],
        search_coverage: [0.5, 0.75, 0.9, 1.0],
        handoffs: [1, 5, 10, 25, 50],
        returning: [1, 3, 5, 10, 20]
      }.freeze

      def initialize(period:, generated_at: Time.current)
        @period = Period.new(key: period, generated_at:)
        @generated_at = generated_at
        @search = SearchAggregate.new(start_at: @period.start_at, end_at: @period.end_at)
      end

      def call
        current_summary = summary_values(period, search)
        previous_summary = previous_summary_values
        {
          generated_at: generated_at.iso8601,
          period: period.to_h,
          privacy_notice: PRIVACY_NOTICE,
          summary: summary(current_summary, previous_summary),
          supply: supply,
          discovery: discovery,
          engagement: engagement,
          trust: trust,
          quotes: quotes,
          moderation: moderation
        }
      end

      private

      attr_reader :period, :generated_at, :search

      def ratio(numerator, denominator)
        {numerator:, denominator:, rate: denominator.zero? ? nil : numerator.fdiv(denominator)}
      end

      def meaningful(scope = ProfessionalDailyActivity.all)
        scope.where(
          "profile_updates > 0 OR evidence_creations > 0 OR relationship_interactions > 0 OR quotes_created > 0"
        )
      end

      def public_profile_ids
        @public_profile_ids ||= ProfessionalProfile.publicly_eligible.pluck(:id)
      end

      def public_relationship_counts
        @public_relationship_counts ||= PublicProfessionalRelationshipQuery.call
          .each_with_object(Hash.new(0)) do |relationship, counts|
          counts[relationship.initiator_professional_id] += 1
          counts[relationship.recipient_professional_id] += 1
        end
      end

      def criteria(profile_ids)
        ids = profile_ids.to_a
        identities = VerificationRequest.identity
          .where(professional_profile_id: ids, status: "approved")
          .where("identity_match_confirmed_at IS NOT NULL OR claimed_birthdate IS NULL")
          .distinct.pluck(:professional_profile_id).to_set
        portfolios = PortfolioItem.active.where(professional_profile_id: ids, status: "approved")
          .group(:professional_profile_id).having("COUNT(*) >= 3").count.keys.to_set
        relationships = ids.select { |id| public_relationship_counts[id] >= 2 }.to_set
        all = identities & portfolios & relationships
        {identity: identities, portfolio: portfolios, relationships:, all:}
      end

      def summary_values(for_period, aggregate)
        published_ids = ProfessionalProfile.where(published_at: for_period.start_at...for_period.end_at).pluck(:id)
        activation = criteria(published_ids)
        totals = aggregate.totals
        eligible_ids = ProfessionalProfile.publicly_eligible.where(published_at: ...for_period.end_at).pluck(:id)
        activity = meaningful.where(activity_date: for_period.start_date..for_period.end_date, professional_id: eligible_ids)
        active_ids = activity.distinct.pluck(:professional_id)
        first_dates = meaningful.where(professional_id: active_ids).group(:professional_id).minimum(:activity_date)
        returning = active_ids.count do |id|
          activity.where(professional_id: id).where("activity_date > ?", first_dates.fetch(id)).exists?
        end
        handoffs = ProfessionalDailyMetric.where(metric_date: for_period.start_date..for_period.end_date).sum(:whatsapp_clicks)
        views = ProfessionalDailyMetric.where(metric_date: for_period.start_date..for_period.end_date).sum(:profile_views)
        {
          published: published_ids.length,
          activated: activation[:all].length,
          activated_denominator: published_ids.length,
          searches_with_results: totals.with_results,
          searches: totals.searches,
          handoffs:,
          views:,
          returning:,
          eligible: eligible_ids.length
        }
      end

      def previous_summary_values
        return unless period.previous_start_at

        previous = Period.allocate
        previous.instance_variable_set(:@start_at, period.previous_start_at)
        previous.instance_variable_set(:@end_at, period.previous_end_at)
        previous.instance_variable_set(:@start_date, period.previous_start_at.in_time_zone(Period::TIME_ZONE).to_date)
        previous.instance_variable_set(:@end_date, (period.previous_end_at - 1.second).in_time_zone(Period::TIME_ZONE).to_date)
        summary_values(previous, SearchAggregate.new(start_at: previous.start_at, end_at: previous.end_at))
      end

      def comparison(key, value, previous_value, denominator: nil, previous_denominator: nil, rate: false)
        if period.key == "since_launch"
          milestones = MILESTONES.fetch(key)
          reached = milestones.select { |candidate| value >= candidate }.max
          next_value = milestones.find { |candidate| value < candidate }
          return {kind: "milestone", reached:, next: next_value, delta: nil, directional: false}
        end

        directional = [denominator, previous_denominator].compact.any? { |sample| sample < 5 }
        delta = value - previous_value
        {kind: rate ? "percentage_points" : "count", reached: nil, next: nil, delta:, directional:}
      end

      def summary(current, previous)
        current_stock = public_profile_ids.length
        published_comparison = comparison(:published, current[:published], previous&.dig(:published).to_i)
        activated_rate = ratio(current[:activated], current[:activated_denominator])
        activated_comparison = comparison(
          :activated, current[:activated], previous&.dig(:activated).to_i,
          denominator: current[:activated_denominator], previous_denominator: previous&.dig(:activated_denominator)
        )
        coverage = ratio(current[:searches_with_results], current[:searches])
        previous_coverage = previous ? ratio(previous[:searches_with_results], previous[:searches]) : nil
        coverage_comparison = comparison(
          :search_coverage, coverage[:rate].to_f, previous_coverage&.dig(:rate).to_f,
          denominator: coverage[:denominator], previous_denominator: previous_coverage&.dig(:denominator), rate: true
        )
        contact_rate = ratio(current[:handoffs], current[:views])
        contact_comparison = comparison(
          :handoffs, current[:handoffs], previous&.dig(:handoffs).to_i,
          denominator: current[:views], previous_denominator: previous&.dig(:views)
        )
        returning_rate = ratio(current[:returning], current[:eligible])
        returning_comparison = comparison(
          :returning, current[:returning], previous&.dig(:returning).to_i,
          denominator: current[:eligible], previous_denominator: previous&.dig(:eligible)
        )
        {
          published: {value: current[:published], current_stock:, metric_type: "flow", comparison: published_comparison},
          activated: activated_rate.merge(metric_type: "cohort_outcome", comparison: activated_comparison),
          search_coverage: coverage.merge(metric_type: "flow", comparison: coverage_comparison),
          handoffs: contact_rate.merge(metric_type: "flow", comparison: contact_comparison),
          returning: returning_rate.merge(metric_type: "cohort_outcome", comparison: returning_comparison)
        }
      end

      def supply
        cohort = ProfessionalProfile
          .joins(:user_account)
          .where(user_accounts: {registered_at: period.start_at...period.end_at})
        ids = cohort.pluck(:id)
        published = cohort.where.not(published_at: nil).pluck(:id)
        verified = criteria(published)[:identity].length
        activated = criteria(published)[:all].length
        values = [ids.length, published.length, verified, activated]
        keys = %w[registered published verified activated]
        labels = ["Cadastrados", "Publicados", "Identidade verificada", "Ativados"]
        descriptions = ["telefone confirmado", nil, "dentro dos publicados", "cumpre os 3 critérios"]
        stages = values.each_with_index.map do |value, index|
          denominator = index.zero? ? value : values[index - 1]
          {key: keys[index], label: labels[index], value:, description: descriptions[index], ratio: ratio(value, denominator)}
        end

        quality_ids = public_profile_ids
        quality = criteria(quality_ids)
        activation = [
          ["identity", "Identidade verificada", "documento aprovado", "i-lucide-badge-check"],
          ["portfolio", "3+ trabalhos", "portfólio suficiente", "i-lucide-images"],
          ["relationships", "2+ conexões", "confiança confirmada", "i-lucide-share-2"],
          ["all", "Perfil ativado", "cumpre os 3 critérios", "i-lucide-badge-check"]
        ].map do |key, label, description, icon|
          ratio(quality.fetch(key.to_sym).length, quality_ids.length).merge(key:, label:, description:, icon:)
        end
        reporting = Rails.configuration.x.berufe.reporting
        {
          target_minimum: reporting.founding_target_minimum,
          target_maximum: reporting.founding_target_maximum,
          funnel: stages,
          activation:
        }
      end

      def discovery
        totals = search.totals
        services = Service.where(id: search.rows.filter_map(&:service_id)).index_by(&:id)
        demand_totals = search.rows.each_with_object(Hash.new(0)) do |row, counts|
          counts[row.service_id] += row.searches if row.service_id
        end
        sorted = demand_totals.sort_by { |id, count| [-count, services.fetch(id).name] }
        demand = sorted.first(5).map { |id, value| {label: services.fetch(id).name, value:} }
        other_count = sorted.drop(5).sum(&:last)
        gaps = search.rows.filter_map do |row|
          gap_searches = row.zero_results + row.thin_results
          next if gap_searches < period.threshold

          service = services[row.service_id]
          next if row.service_id.nil? && row.unmatched_query.blank?

          professionals = service ? searchable_supply(service.id, row.neighborhood_code) : 0
          status = if service.nil?
            "outside_mvp"
          elsif service.is_active?
            "active"
          else
            "inactive"
          end
          {
            service: service&.name || row.unmatched_query.titleize,
            location: Neighborhood.find_by(code: row.neighborhood_code)&.name || "Joinville",
            searches: gap_searches,
            zero_result_searches: row.zero_results,
            thin_result_searches: row.thin_results,
            professionals:,
            catalog_status: status
          }
        end.sort_by { |gap| [-gap[:zero_result_searches], -gap[:searches], gap[:professionals], gap[:service]] }.first(5)
        stages = [
          ["searches", "Buscas realizadas", totals.searches],
          ["results", "Com algum resultado", totals.with_results],
          ["choice", "Com 3+ opções", totals.with_three_results],
          ["profile_open", "Com perfil aberto", totals.with_profile_open],
          ["contact", "Contato iniciado", totals.with_whatsapp_handoff]
        ].map { |key, label, value| ratio(value, totals.searches).merge(key:, label:) }
        metrics = ProfessionalDailyMetric.where(metric_date: period.start_date..period.end_date)
        {
          stages:,
          profile_views: metrics.sum(:profile_views),
          whatsapp_handoffs: metrics.sum(:whatsapp_clicks),
          demand:,
          other_count:,
          gaps:
        }
      end

      def searchable_supply(service_id, neighborhood_code)
        relation = ProfessionalProfile.publicly_eligible
          .joins(published_revision: %i[professional_profile_services professional_profile_service_areas])
          .where(professional_profile_services: {service_id:})
        if neighborhood_code
          relation = relation.where(
            "professional_profile_service_areas.neighborhood_code IS NULL OR professional_profile_service_areas.neighborhood_code = ?",
            neighborhood_code
          )
        end
        relation.distinct.count
      end

      def engagement
        eligible_ids = ProfessionalProfile.publicly_eligible.where(published_at: ...period.end_at).pluck(:id)
        scoped = meaningful.where(activity_date: period.start_date..period.end_date, professional_id: eligible_ids)
        active_ids = scoped.distinct.pluck(:professional_id)
        first_dates = meaningful.where(professional_id: active_ids).group(:professional_id).minimum(:activity_date)
        returning = active_ids.count { |id| scoped.where(professional_id: id).where("activity_date > ?", first_dates.fetch(id)).exists? }
        actions = {
          profile: ["Atualizou perfil", :profile_updates],
          trust: ["Criou evidência", :evidence_creations],
          relationship: ["Interagiu com a rede", :relationship_interactions],
          quote: ["Criou orçamento", :quotes_created]
        }.map do |key, (label, column)|
          condition = ProfessionalDailyActivity.arel_table[column].gt(0)
          {key: key.to_s, label:, value: scoped.where(condition).distinct.count(:professional_id)}
        end
        active_weeks = frequency_buckets(eligible_ids)
        {
          eligible_professionals: eligible_ids.length,
          meaningful_actives: active_ids.length,
          meaningful_active_rate: ratio(active_ids.length, eligible_ids.length),
          returning_professionals: returning,
          returning_rate: ratio(returning, eligible_ids.length),
          active_weeks:,
          actions:,
          cohorts: retention_cohorts
        }
      end

      def frequency_buckets(eligible_ids)
        if period.key == "last_7_days"
          active = meaningful.where(activity_date: period.start_date..period.end_date, professional_id: eligible_ids).distinct.count(:professional_id)
          return [
            {key: "none", label: "Sem ação", value: eligible_ids.length - active},
            {key: "active", label: "Ativos", value: active}
          ]
        end

        current_week = period.end_date.beginning_of_week(:monday)
        starts = 4.times.map { |offset| current_week - ((offset + 1) * 7) }.reverse
        counts = meaningful.where(activity_date: starts.first..(current_week - 1), professional_id: eligible_ids)
          .pluck(:professional_id, :activity_date)
          .group_by(&:first)
          .transform_values { |rows| rows.map { |(_, date)| date.beginning_of_week(:monday) }.uniq.length }
        distribution = eligible_ids.map { |id| counts.fetch(id, 0) }
        [
          {key: "none", label: "0 semanas", value: distribution.count(0)},
          {key: "one", label: "1 semana", value: distribution.count(1)},
          {key: "two_three", label: "2–3 semanas", value: distribution.count { |value| value.in?([2, 3]) }},
          {key: "four", label: "4 semanas", value: distribution.count(4)}
        ]
      end

      def retention_cohorts
        profiles = ProfessionalProfile.where(published_at: period.start_at...period.end_at).where.not(published_at: nil).to_a
        profiles.group_by { |profile| profile.published_at.in_time_zone(Period::TIME_ZONE).to_date.beginning_of_week(:monday) }
          .sort_by(&:first).last(12).map do |week, cohort|
            {
              cohort: "#{Period.format_date(week)}–#{Period.format_date(week + 6)}",
              size: cohort.length,
              week1: retained_count(cohort, 7, 13),
              week4: retained_count(cohort, 28, 34)
            }
          end
      end

      def retained_count(cohort, first_offset, last_offset)
        return nil unless cohort.all? do |profile|
          period.end_date > profile.published_at.in_time_zone(Period::TIME_ZONE).to_date + last_offset
        end

        cohort.count do |profile|
          date = profile.published_at.in_time_zone(Period::TIME_ZONE).to_date
          meaningful.where(professional_id: profile.id, activity_date: (date + first_offset)..(date + last_offset)).exists?
        end
      end

      def trust
        cohort = ProfessionalRelationship.where(created_at: period.start_at...period.end_at)
        started = cohort.count
        responded = cohort.where.not(responded_at: nil).count
        public_ids = PublicProfessionalRelationshipQuery.call
          .where(id: cohort.select(:id))
          .pluck(:id)
        approved = public_ids.length
        {
          funnels: [{
            key: "relationships",
            label: "Conexões profissionais",
            started:,
            responded:,
            approved:,
            response_rate: ratio(responded, started),
            approval_rate: ratio(approved, responded)
          }]
        }
      end

      def quotes
        cohort = Quote.where(created_at: period.start_at...period.end_at)
        created = cohort.count
        shared = cohort.where(status: "shared").where.not(shared_at: nil).count
        creator_counts = cohort.group(:professional_id).count
        {
          created:,
          shared:,
          share_rate: ratio(shared, created),
          unique_creators: creator_counts.length,
          repeat_creators: creator_counts.count { |_, count| count >= 2 }
        }
      end

      def moderation
        pending = ModerationQueueSummaryQuery.new.call(now: generated_at)
        actions = ModerationAction.where(created_at: period.start_at...period.end_at)
        reviewed = actions.where(action: %w[approved rejected]).count
        rejected = actions.where(action: "rejected").count
        durations = moderation_durations(actions.where(action: %w[approved rejected]))
        target_counts = actions.group(:target_type).count
        reporting = Rails.configuration.x.berufe.reporting
        {
          pending: pending[:pending_count],
          oldest_pending_hours: pending[:oldest_pending_submitted_at] ? ((generated_at - pending[:oldest_pending_submitted_at]) / 1.hour).round(1) : 0,
          oldest_pending_target_hours: reporting.moderation_oldest_pending_target_hours,
          median_review_hours: percentile(durations, 0.5),
          p90_review_hours: percentile(durations, 0.9),
          rejected:,
          reviewed:,
          approval_rate: ratio(reviewed - rejected, reviewed),
          hidden: actions.where(action: "hidden").count,
          by_target_type: ModerationAction::TARGET_TYPES.index_with { |type| target_counts.fetch(type, 0) }
        }
      end

      def moderation_durations(actions)
        submitted = {
          "profile_revision" => ProfessionalProfileRevision.where(id: actions.where(target_type: "profile_revision").select(:target_id)).pluck(:id, :submitted_at).to_h,
          "profile_photo" => ProfessionalProfilePhoto.where(id: actions.where(target_type: "profile_photo").select(:target_id)).pluck(:id, :submitted_at).to_h,
          "portfolio_item" => PortfolioItem.where(id: actions.where(target_type: "portfolio_item").select(:target_id)).pluck(:id, :submitted_at).to_h,
          "verification_request" => VerificationRequest.where(id: actions.where(target_type: "verification_request").select(:target_id)).pluck(:id, :submitted_at).to_h
        }
        actions.filter_map do |action|
          start = submitted.dig(action.target_type, action.target_id)
          ((action.created_at - start) / 1.hour) if start
        end.sort
      end

      def percentile(values, fraction)
        return 0 if values.empty?

        values[[(values.length * fraction).ceil - 1, 0].max].round(1)
      end
    end
  end
end
