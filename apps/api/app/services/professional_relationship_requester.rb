# frozen_string_literal: true

class ProfessionalRelationshipRequester
  class Invalid < StandardError
    attr_reader :field_errors

    def initialize(field_errors)
      @field_errors = field_errors
      super("invalid professional relationship")
    end
  end

  class Duplicate < StandardError; end
  class Ineligible < StandardError; end

  MAXIMUM_EXTERNAL_SERVICES = 10

  def initialize(notifier: ProfessionalNotificationCreator.new)
    @notifier = notifier
  end

  def call(initiator:, target:, relationship_type:, context_note:, now: Time.current)
    ProfessionalRelationship.transaction do
      initiator.lock!
      ensure_eligible_initiator!(initiator)
      recipient, source, attested_at = resolve_target!(initiator:, target:, now:)
      ensure_distinct_profiles!(initiator, recipient)
      ensure_not_duplicate!(initiator, recipient, relationship_type)

      relationship = ProfessionalRelationship.create!(
        initiator_professional: initiator,
        recipient_professional: recipient,
        relationship_type:,
        context_note:,
        status: "pending",
        source:,
        contact_publication_attested_at: attested_at
      )
      ProfessionalDailyActivity.increment!(
        professional_id: initiator.id,
        counter: :relationship_interactions,
        occurred_at: now
      )
      @notifier.call(
        recipient: recipient.user_account,
        notification_type: "relationship_request_received",
        idempotency_key: "relationship:#{relationship.id}:requested",
        occurred_at: now
      )
      relationship
    end
  rescue BrazilianPhoneNumber::Invalid
    raise Invalid.new(phone: ["informe um celular brasileiro com DDD"])
  rescue ActiveRecord::RecordInvalid => error
    raise Invalid.new(error.record.errors.to_hash(true))
  rescue ActiveRecord::RecordNotUnique
    raise Duplicate
  end

  private

  def resolve_target!(initiator:, target:, now:)
    values = target.to_h.deep_symbolize_keys
    case values[:type].to_s
    when "profile"
      recipient = ProfessionalProfile.publicly_viewable.find(values[:professional_profile_id])
      [recipient, "existing_profile", nil]
    when "phone"
      [resolve_phone_target!(initiator:, values:, now:), "external_phone", now]
    else
      raise Invalid.new(target: ["escolha um profissional da Berufe ou informe um contato externo"])
    end
  end

  def resolve_phone_target!(initiator:, values:, now:)
    name = values[:name].to_s.squish
    raise Invalid.new(name: ["deve ter entre 3 e 70 caracteres"]) unless name.length.between?(3, 70)
    unless values[:contact_publication_attested] == true
      raise Invalid.new(contact_publication_attested: ["confirme que pode compartilhar estes dados"])
    end

    phone_e164 = BrazilianPhoneNumber.normalize(values[:phone])
    if phone_e164 == initiator.user_account.phone_e164
      raise Invalid.new(phone: ["não pode ser o seu próprio telefone"])
    end

    services = resolve_services!(values[:service_ids])
    coverage = resolve_coverage!(values[:coverage])
    UserAccount.insert_all(
      [{
        phone_e164:,
        role: "professional",
        status: "active",
        created_at: now,
        updated_at: now
      }],
      unique_by: :index_user_accounts_on_phone_e164
    )
    account = UserAccount.find_by!(phone_e164:)
    account.lock!
    raise Invalid.new(phone: ["este contato não está disponível"]) unless account.professional? && account.active?

    account.professional_profile || create_external_profile!(
      account:,
      name:,
      phone_e164:,
      services:,
      coverage:,
      now:
    )
  end

  def resolve_services!(service_ids)
    ids = Array(service_ids).map(&:to_s).reject(&:blank?).uniq
    if ids.length > MAXIMUM_EXTERNAL_SERVICES
      raise Invalid.new(service_ids: ["escolha no máximo #{MAXIMUM_EXTERNAL_SERVICES} serviços"])
    end
    services = Service.publicly_active.where(id: ids).order(:sort_order, :name, :id).to_a
    return services if services.length == ids.length

    raise Invalid.new(service_ids: ["escolha apenas serviços ativos do catálogo"])
  end

  def resolve_coverage!(coverage)
    values = coverage.to_h.deep_symbolize_keys
    city_code = values[:city_code].to_s.presence
    whole_city = values[:whole_city] == true
    codes = Array(values[:neighborhood_codes]).map(&:to_s).reject(&:blank?).uniq
    if whole_city && codes.any?
      raise Invalid.new(coverage: ["não combine a cidade inteira com bairros específicos"])
    end
    return {city: nil, whole_city: false, neighborhoods: []} if city_code.nil? && !whole_city && codes.empty?
    raise Invalid.new(coverage: ["selecione uma cidade"]) unless city_code

    city = City.find_by(code: city_code)
    raise Invalid.new(coverage: ["selecione uma cidade disponível"]) unless city
    if !whole_city && codes.empty?
      raise Invalid.new(coverage: ["escolha a cidade inteira ou ao menos um bairro"])
    end

    neighborhoods = city.neighborhoods.where(code: codes).ordered.to_a
    return {city:, whole_city:, neighborhoods:} if neighborhoods.length == codes.length

    raise Invalid.new(coverage: ["escolha apenas bairros da cidade selecionada"])
  end

  def create_external_profile!(account:, name:, phone_e164:, services:, coverage:, now:)
    profile = ProfessionalProfile.create!(
      user_account: account,
      creation_source: "external",
      external_published_at: now,
      profile_status: "published",
      display_name: name,
      whatsapp_e164: phone_e164
    )
    revision = profile.working_revision
    revision.update!(
      profile_type: "external",
      coverage_city_code: coverage[:city]&.code,
      covers_whole_city: coverage[:whole_city],
      status: "pending_review",
      submitted_at: now
    )
    services.each_with_index do |service, index|
      revision.professional_profile_services.create!(service:, is_primary: index.zero?)
    end
    coverage[:neighborhoods].each do |neighborhood|
      revision.professional_profile_service_areas.create!(neighborhood_code: neighborhood.code)
    end
    profile.update!(published_revision: revision, working_revision: revision)
    profile
  end

  def ensure_eligible_initiator!(initiator)
    account = initiator.user_account
    return if account.active? && account.registered? && account.phone_verified? &&
      initiator.verification_requests.identity.exists?(status: "approved")

    raise Ineligible
  end

  def ensure_distinct_profiles!(initiator, recipient)
    return unless initiator.id == recipient.id

    raise Invalid.new(professional_profile_id: ["não pode ser o próprio perfil"])
  end

  def ensure_not_duplicate!(initiator, recipient, relationship_type)
    return unless ProfessionalRelationship.active.exists?(
      initiator_professional: initiator,
      recipient_professional: recipient,
      relationship_type:
    )

    raise Duplicate
  end
end
