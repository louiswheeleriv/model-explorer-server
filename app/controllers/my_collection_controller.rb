# frozen_string_literal: true

class MyCollectionController < ApplicationController

  NONE = '__NONE__'

  def index
    require_logged_in!
  end

  def show_faction
    require_logged_in!
    
    @faction = Faction.find_by(name: params[:faction_name])
  end

  def add_faction
    require_logged_in!
    
    faction_id = params[:faction_id]
    faction = ::Faction.find_by(id: faction_id)
    raise 'Faction not found' unless faction

    user_faction = ::UserFaction.find_by(user_id: current_user_id, faction_id: faction_id)
    raise "Faction #{faction.name} is already in your collection" if user_faction

    user_faction = ::UserFaction.create(user_id: current_user_id, faction_id: faction_id)
    render status: 200, json: { status: 200, user_faction: user_faction, faction: faction }
  end

  def add_user_model
    require_logged_in!

    faction_id = params[:faction_id]
    model_id = params[:model_id]
    quantity_by_status = params[:quantity_by_status]
    faction = ::Faction.find_by(id: faction_id)
    return render status: 400, json: { status: 400, error: "Faction #{faction_id} not found." } unless faction

    user_faction = faction.user_factions.find_by(user_id: current_user_id)
    return render status: 400, json: { status: 400, error: "No UserFaction found for Faction #{faction_id}"} unless user_faction

    model = ::Model.find_by(id: model_id)
    return render status: 400, json: { status: 400, error: "Model #{model_id} not found." } unless model

    user_model = ::UserModel.create!(
      user_id: current_user_id,
      user_faction_id: user_faction.id,
      model_id: model_id,
      name: params[:name],
      user_model_group_id: params[:user_model_group_id],
      qty_unassembled: quantity_by_status['unassembled'],
      qty_assembled: quantity_by_status['assembled'],
      qty_in_progress: quantity_by_status['in_progress'],
      qty_finished: quantity_by_status['finished']
    )

    render status: 200, json: { status: 200, user_model: user_model }
  end

  def edit_user_model
    require_logged_in!
    
    faction_id = params[:faction_id]
    user_model_id = params[:user_model_id]
    quantity_by_status = params[:quantity_by_status]

    faction = ::Faction.find_by(id: faction_id)
    return render status: 400, json: { status: 400, error: "Faction #{faction_id} not found." } unless faction

    user_model = ::UserModel.find_by(id: user_model_id)
    return render status: 400, json: { status: 400, error: "UserModel #{user_model_id} not found." } unless user_model

    if quantity_by_status
      user_model.assign_attributes(
        qty_unassembled: quantity_by_status['unassembled'],
        qty_assembled: quantity_by_status['assembled'],
        qty_in_progress: quantity_by_status['in_progress'],
        qty_finished: quantity_by_status['finished']
      )
    end

    user_model.user_model_group_id = params[:user_model_group_id] if params.key?(:user_model_group_id)
    user_model.name = params[:name] if params.key?(:name)

    user_model.save!

    render status: 200, json: { status: 200, user_model: user_model }
  end

  def delete_user_model
    require_logged_in!

    faction_id = params[:faction_id]
    user_model_id = params[:user_model_id]

    faction = ::Faction.find_by(id: faction_id)
    return render status: 400, json: { status: 400, error: "Faction #{faction_id} not found." } unless faction

    user_model = ::UserModel.find_by(id: user_model_id)
    return render status: 400, json: { status: 400, error: "UserModel #{user_model_id} not found." } unless user_model
    
    user_model.destroy!

    render status: 200, json: { status: 200 }
  end

  def set_user_model_groups
    require_logged_in!

    proposed_groups = params[:user_model_groups]
    return render status: 400, json: { status: 400, error: "Param user_model_groups is required" } unless proposed_groups

    user_faction = ::UserFaction.find_by(user_id: current_user_id, faction_id: params[:faction_id])
    return render status: 400, json: { status: 400, error: "No UserFaction found for Faction #{params[:faction_id]}" } unless user_faction

    ActiveRecord::Base.transaction do
      user_faction
        .user_model_groups
        .where.not(id: proposed_groups.map { |pg| pg['id'] })
        .destroy_all

      proposed_groups.each do |proposed_group|
        ::UserModelGroup.find_or_initialize_by(
          id: proposed_group['id'],
          user_id: current_user_id,
          user_faction_id: user_faction.id,
        ).tap do |group|
          group.assign_attributes(
            name: proposed_group['name'],
            sort_index: proposed_group['sort_index']
          )
        end.save!
      end
    end

    render status: 200, json: { status: 200, user_model_groups: user_faction.reload.user_model_groups.order(sort_index: :asc) }
  end

  def show_user_model
    require_logged_in!
  end

end
