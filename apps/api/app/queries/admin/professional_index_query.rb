# frozen_string_literal: true

module Admin
  class ProfessionalIndexQuery
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100
    MAX_QUERY_LENGTH = 100
    TRISTATES = %w[all yes no].freeze
    DEFAULT_SORT = "recent"
    SORTS = %w[recent last_login_desc name_asc].freeze

    BASE_JOIN_SQL = <<~SQL.squish.freeze
      LEFT JOIN professional_profiles ON professional_profiles.user_account_id = user_accounts.id
      LEFT JOIN professional_profile_revisions AS display_revisions
        ON display_revisions.id = COALESCE(
             professional_profiles.published_revision_id,
             professional_profiles.working_revision_id
           )
      LEFT JOIN cities ON cities.code = display_revisions.coverage_city_code
      LEFT JOIN states ON states.code = cities.state_code
    SQL

    NORMALIZED_NAME_SQL = <<~SQL.squish.freeze
      translate(
        lower(coalesce(display_revisions.display_name, '')),
        'áàâãäéèêëíìîïóòôõöúùûüç',
        'aaaaaeeeeiiiiooooouuuuc'
      ) LIKE :pattern
    SQL

    PHONE_MATCH_SQL = <<~SQL.squish.freeze
      regexp_replace(coalesce(user_accounts.phone_e164, ''), '[^0-9]', '', 'g') LIKE :phone_pattern
      OR regexp_replace(coalesce(display_revisions.whatsapp_e164, ''), '[^0-9]', '', 'g') LIKE :phone_pattern
    SQL

    IDENTITY_VERIFIED_EXISTS_SQL = <<~SQL.squish.freeze
      EXISTS (
        SELECT 1 FROM verification_requests
        WHERE verification_requests.professional_profile_id = professional_profiles.id
          AND verification_requests.verification_type = 'identity'
          AND verification_requests.status = 'approved'
      )
    SQL

    ONBOARDING_UNFINISHED_SQL = <<~SQL.squish.freeze
      professional_profiles.id IS NULL OR professional_profiles.profile_status = 'draft'
    SQL

    SELECT_SQL = <<~SQL.squish.freeze
      user_accounts.id,
      professional_profiles.id AS professional_profile_id,
      professional_profiles.public_slug,
      professional_profiles.profile_status,
      professional_profiles.published_at,
      display_revisions.display_name,
      cities.name AS city_name,
      states.abbreviation AS state_abbreviation,
      user_accounts.phone_e164,
      user_accounts.phone_verified_at,
      user_accounts.registered_at,
      user_accounts.last_login_at,
      user_accounts.login_count,
      user_accounts.status AS account_status,
      (#{IDENTITY_VERIFIED_EXISTS_SQL}) AS identity_verified,
      (SELECT COUNT(*) FROM portfolio_items
         WHERE portfolio_items.professional_profile_id = professional_profiles.id
           AND portfolio_items.deleted_at IS NULL) AS portfolio_count,
      (SELECT COUNT(*) FROM professional_relationships
         WHERE (professional_relationships.initiator_professional_id = professional_profiles.id
             OR professional_relationships.recipient_professional_id = professional_profiles.id)
           AND professional_relationships.status = 'accepted'
           AND professional_relationships.deleted_at IS NULL) AS reference_count,
      (SELECT COUNT(*) FROM customers
         WHERE customers.professional_id = professional_profiles.id) AS customer_count,
      (SELECT COUNT(*) FROM quotes
         WHERE quotes.professional_id = professional_profiles.id) AS quote_count
    SQL

    Result = Data.define(:professionals, :page, :per_page, :total_count, :summary) do
      def total_pages
        total_count.zero? ? 0 : (total_count.to_f / per_page).ceil
      end
    end

    class Invalid < StandardError
      attr_reader :field_errors

      def initialize(field_errors)
        @field_errors = field_errors
        super("invalid administrator professional directory query")
      end
    end

    def call(page: 1, per_page: DEFAULT_PER_PAGE, q: nil, phone: nil, city: nil, state: nil,
      identity_verified: "all", onboarding_finished: "all", sort: DEFAULT_SORT)
      normalized = normalize(
        page:, per_page:, q:, phone:, city:, state:, identity_verified:, onboarding_finished:, sort:
      )

      scope = base_scope
      scope = apply_query(scope, normalized[:q])
      scope = apply_phone(scope, normalized[:phone])
      scope = apply_city(scope, normalized[:city])
      scope = apply_state(scope, normalized[:state])
      scope = apply_identity(scope, normalized[:identity_verified])
      scope = apply_onboarding(scope, normalized[:onboarding_finished])

      total_count = scope.count
      summary = summarize(scope)
      professionals = apply_sort(scope, normalized[:sort])
        .select(Arel.sql(SELECT_SQL))
        .limit(normalized[:per_page])
        .offset((normalized[:page] - 1) * normalized[:per_page])
        .to_a

      Result.new(professionals:, page: normalized[:page], per_page: normalized[:per_page], total_count:, summary:)
    end

    private

    def base_scope
      UserAccount.where(role: "professional").joins(BASE_JOIN_SQL)
    end

    def normalize(page:, per_page:, q:, phone:, city:, state:, identity_verified:, onboarding_finished:, sort:)
      errors = {}
      normalized_page = Integer(page.to_s.presence || 1, exception: false)
      normalized_per_page = Integer(per_page.to_s.presence || DEFAULT_PER_PAGE, exception: false)
      errors[:page] = ["deve ser maior que zero"] unless normalized_page&.positive?
      unless normalized_per_page&.between?(1, MAX_PER_PAGE)
        errors[:per_page] = ["deve estar entre 1 e #{MAX_PER_PAGE}"]
      end

      normalized_q = q.to_s.strip
      if normalized_q.length > MAX_QUERY_LENGTH
        errors[:q] = ["use um nome com até #{MAX_QUERY_LENGTH} caracteres"]
      end

      normalized_phone_digits = phone.to_s.gsub(/\D/, "")
      errors[:phone] = ["informe ao menos um dígito"] if phone.present? && normalized_phone_digits.blank?

      normalized_city = city.to_s.strip.presence
      if normalized_city && !normalized_city.match?(/\A\d{7}\z/)
        errors[:city] = ["use um código de cidade IBGE válido"]
      end

      normalized_state = state.to_s.strip.upcase.presence
      if normalized_state && !normalized_state.match?(/\A[A-Z]{2}\z/)
        errors[:state] = ["use uma UF válida"]
      end

      normalized_identity = identity_verified.to_s.presence || "all"
      unless TRISTATES.include?(normalized_identity)
        errors[:identity_verified] = ["use um dos valores: #{TRISTATES.join(", ")}"]
      end

      normalized_onboarding = onboarding_finished.to_s.presence || "all"
      unless TRISTATES.include?(normalized_onboarding)
        errors[:onboarding_finished] = ["use um dos valores: #{TRISTATES.join(", ")}"]
      end

      normalized_sort = sort.to_s.presence || DEFAULT_SORT
      errors[:sort] = ["use um dos valores: #{SORTS.join(", ")}"] unless SORTS.include?(normalized_sort)

      raise Invalid, errors if errors.any?

      {
        page: normalized_page,
        per_page: normalized_per_page,
        q: normalized_q.presence && ActiveSupport::Inflector.transliterate(normalized_q).downcase,
        phone: normalized_phone_digits.presence,
        city: normalized_city,
        state: normalized_state,
        identity_verified: normalized_identity,
        onboarding_finished: normalized_onboarding,
        sort: normalized_sort
      }
    end

    def apply_query(scope, normalized_q)
      return scope unless normalized_q

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(normalized_q)}%"
      scope.where(NORMALIZED_NAME_SQL, pattern:)
    end

    def apply_phone(scope, phone_digits)
      return scope unless phone_digits

      phone_pattern = "%#{ActiveRecord::Base.sanitize_sql_like(phone_digits)}%"
      scope.where(PHONE_MATCH_SQL, phone_pattern:)
    end

    def apply_city(scope, city_code)
      return scope unless city_code

      scope.where(cities: {code: city_code})
    end

    def apply_state(scope, state_abbreviation)
      return scope unless state_abbreviation

      scope.where(states: {abbreviation: state_abbreviation})
    end

    def apply_identity(scope, value)
      case value
      when "yes"
        scope.where(IDENTITY_VERIFIED_EXISTS_SQL)
      when "no"
        scope.where.not(IDENTITY_VERIFIED_EXISTS_SQL)
      else
        scope
      end
    end

    def apply_onboarding(scope, value)
      case value
      when "yes"
        scope.where.not(ONBOARDING_UNFINISHED_SQL)
      when "no"
        scope.where(ONBOARDING_UNFINISHED_SQL)
      else
        scope
      end
    end

    def apply_sort(scope, sort)
      case sort
      when "last_login_desc"
        scope.order(Arel.sql("user_accounts.last_login_at DESC NULLS LAST, user_accounts.id DESC"))
      when "name_asc"
        scope.order(Arel.sql("lower(coalesce(display_revisions.display_name, '')) ASC NULLS LAST, user_accounts.id DESC"))
      else
        scope.order(Arel.sql(<<~SQL.squish))
          user_accounts.registered_at DESC NULLS LAST, user_accounts.created_at DESC, user_accounts.id DESC
        SQL
      end
    end

    def summarize(scope)
      counts = scope.pick(
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE professional_profiles.profile_status = 'published')"),
        Arel.sql("COUNT(*) FILTER (WHERE professional_profiles.profile_status = 'suspended')"),
        Arel.sql("COUNT(*) FILTER (WHERE NOT (#{ONBOARDING_UNFINISHED_SQL}))"),
        Arel.sql("COUNT(*) FILTER (WHERE #{IDENTITY_VERIFIED_EXISTS_SQL})")
      )
      %i[total published suspended onboarding_finished identity_verified].zip(counts).to_h
    end
  end
end
