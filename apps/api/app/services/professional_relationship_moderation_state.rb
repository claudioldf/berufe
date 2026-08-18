# frozen_string_literal: true

class ProfessionalRelationshipModerationState
  NOT_PROVIDED = Object.new.freeze
  STATES_BY_ACTION = {
    "approved" => "approved",
    "restored" => "approved",
    "rejected" => "rejected",
    "hidden" => "hidden"
  }.freeze

  def self.call(relationship, latest_action: NOT_PROVIDED)
    return unless relationship.status == "accepted"

    action = if latest_action.equal?(NOT_PROVIDED)
      latest_action_for(relationship.id)
    else
      latest_action
    end
    action ? STATES_BY_ACTION.fetch(action.action) : "pending_review"
  end

  def self.latest_action_for(relationship_id)
    ModerationAction
      .where(target_type: "professional_relationship", target_id: relationship_id)
      .order(created_at: :desc, id: :desc)
      .first
  end

  def self.latest_actions_by_target_id(relationship_ids)
    relationship_ids = Array(relationship_ids)
    return {} if relationship_ids.empty?

    ModerationAction
      .where(target_type: "professional_relationship", target_id: relationship_ids)
      .order(created_at: :desc, id: :desc)
      .each_with_object({}) do |action, latest|
        latest[action.target_id] ||= action
      end
  end
end
