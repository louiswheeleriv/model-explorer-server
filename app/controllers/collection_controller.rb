# frozen_string_literal: true

class CollectionController < ApplicationController

  def index
    redirect_home_unless_logged_in!
  end

  def show_faction
  end

  def show_user_model
  end

  def add_faction
    redirect_home_unless_logged_in!
    
    faction_id = params[:faction_id]
    faction = ::Faction.find_by(id: faction_id)
    raise 'Faction not found' unless faction

    user_faction = nil
    ActiveRecord::Base.transaction do
      user_faction = ::UserFaction.create(
        user_id: current_user_id,
        faction_id: faction_id,
        name: params[:name]
      )
      ::UserModelGroup.create(
        user_id: current_user_id,
        user_faction: user_faction,
        name: 'Characters',
        sort_index: 0
      )
      ::UserModelGroup.create(
        user_id: current_user_id,
        user_faction: user_faction,
        name: 'Infantry',
        sort_index: 1
      )
      ::UserModelGroup.create(
        user_id: current_user_id,
        user_faction: user_faction,
        name: 'Vehicles',
        sort_index: 2
      )
    end
    render status: 200, json: { status: 200, user_faction: user_faction, faction: faction }
  end

  def update_user_faction
    redirect_home_unless_logged_in!

    user_faction_id = params[:user_faction_id]
    user_faction = ::UserFaction.find_by(
      user_id: current_user_id,
      id: user_faction_id
    )
    return render status: 400, json: { status: 400, error: 'Faction not found in your collection' } unless user_faction

    user_faction.name = params[:name] if params.key?(:name)
    user_faction.notes = params[:notes] if params.key?(:notes)

    Rails.logger.info "About to save UserFaction #{user_faction.id}: notes=#{user_faction.notes.inspect}, changed=#{user_faction.changed?}, changes=#{user_faction.changes.inspect}"

    user_faction.save!

    Rails.logger.info "After save UserFaction #{user_faction.id}: notes=#{user_faction.reload.notes.inspect}"

    render status: 200, json: { status: 200, user_faction: user_faction }
  end

  def delete_user_faction
    redirect_home_unless_logged_in!
    
    user_faction_id = params[:user_faction_id]
    user_faction = ::UserFaction.find_by(
      user_id: current_user_id,
      id: user_faction_id
    )
    return render status: 400, json: { status: 400, error: 'Faction not found in your collection' } unless user_faction

    user_faction.destroy!
    render status: 200, json: { status: 200 }
  end

  def add_user_model
    redirect_home_unless_logged_in!

    user_faction_id = params[:user_faction_id]
    model_id = params[:model_id]
    quantity_by_status = params[:quantity_by_status]
    user_faction = ::UserFaction.find_by(
      user_id: current_user_id,
      id: user_faction_id
    )
    return render status: 400, json: { status: 400, error: 'Faction not found in your collection' } unless user_faction

    model = ::Model.find_by(id: model_id)
    return render status: 400, json: { status: 400, error: "Model #{model_id} not found." } unless model

    user_model = ::UserModel.create!(
      user_id: current_user_id,
      user_faction_id: user_faction_id,
      model_id: model_id,
      name: params[:name].presence,
      user_model_group_id: params[:user_model_group_id],
      qty_unassembled: quantity_by_status['unassembled'],
      qty_assembled: quantity_by_status['assembled'],
      qty_in_progress: quantity_by_status['in_progress'],
      qty_finished: quantity_by_status['finished']
    )

    render status: 200, json: { status: 200, user_model: user_model }
  end

  def edit_user_model
    redirect_home_unless_logged_in!
    
    user_model_id = params[:user_model_id]
    quantity_by_status = params[:quantity_by_status]

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
    user_model.notes = params[:notes] if params.key?(:notes)

    user_model.save!

    render status: 200, json: { status: 200, user_model: user_model }
  end

  def delete_user_model
    redirect_home_unless_logged_in!

    user_model_id = params[:user_model_id]
    user_model = ::UserModel.find_by(id: user_model_id)
    return render status: 400, json: { status: 400, error: "UserModel #{user_model_id} not found." } unless user_model
    
    user_model.destroy!

    render status: 200, json: { status: 200 }
  end

  def create_group
    redirect_home_unless_logged_in!

    user_faction_id = params[:user_faction_id]
    new_group_name = params[:name]

    user_faction = ::UserFaction.find_by(user_id: current_user_id, id: user_faction_id)
    return render status: 400, json: { status: 400, error: "UserFaction #{user_faction_id} not found" } unless user_faction

    existing_group = user_faction.user_model_groups.find_by(name: new_group_name)
    return render status: 400, json: { status: 400, error: "Group #{new_group_name} already exists in UserFaction" } if existing_group

    group = ::UserModelGroup.create!(
      user_id: current_user_id,
      user_faction_id: user_faction_id,
      name: new_group_name,
      sort_index: user_faction.user_model_groups.count
    )

    render status: 200, json: { status: 200, user_model_group: group }
  end

  def set_user_model_groups
    redirect_home_unless_logged_in!

    proposed_groups = params[:user_model_groups]
    return render status: 400, json: { status: 400, error: "Param user_model_groups is required" } unless proposed_groups

    user_faction = ::UserFaction.find_by(
      user_id: current_user_id,
      id: params[:user_faction_id]
    )
    return render status: 400, json: { status: 400, error: 'Faction not found in your collection' } unless user_faction

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

  def set_user_model_image_associations
    redirect_home_unless_logged_in!

    user_model_id = params[:user_model_id]
    user_model = ::UserModel.find_by(id: user_model_id)
    return render status: 400, json: { status: 400, error: "UserModel #{user_model_id} not found." } unless user_model

    proposed_images = params[:images]

    ActiveRecord::Base.transaction do
      user_model
        .user_image_associations
        .destroy_all

      proposed_images.each do |proposed_image|
        user_image_id = proposed_image['user_image_id'] ||
          ::UserImage.create!(
            user_id: current_user_id,
            url: proposed_image['url']
          ).id
        
        ::UserImageAssociation.create!(
          user_id: current_user_id,
          user_model_id: user_model.id,
          user_image_id: user_image_id,
          sort_index: proposed_image['sort_index']
        )
      end
    end

    render status: 200, json: {
      status: 200,
      images: user_model.reload.user_image_associations.order(sort_index: :asc).map do |assoc|
        {
          user_image_association: assoc,
          user_image: assoc.user_image
        }
      end
    }
  end

  def set_user_faction_image_associations
    redirect_home_unless_logged_in!

    user_faction = ::UserFaction.find_by(
      user_id: current_user_id,
      id: params[:user_faction_id]
    )
    return render status: 400, json: { status: 400, error: 'Faction not found in your collection' } unless user_faction

    proposed_images = params[:images]

    ActiveRecord::Base.transaction do
      user_faction
        .user_image_associations
        .destroy_all

      proposed_images.each do |proposed_image|
        user_image_id = proposed_image['user_image_id'] ||
          ::UserImage.create!(
            user_id: current_user_id,
            url: proposed_image['url']
          ).id
        
        ::UserImageAssociation.create!(
          user_id: current_user_id,
          user_faction_id: user_faction.id,
          user_image_id: user_image_id,
          sort_index: proposed_image['sort_index']
        )
      end
    end

    render status: 200, json: {
      status: 200,
      images: user_faction.reload.user_image_associations.order(sort_index: :asc).map do |assoc|
        {
          user_image_association: assoc,
          user_image: assoc.user_image
        }
      end
    }
  end

  def game_systems
    render status: 200, json: {
      status: 200,
      game_systems:
        ::GameSystem
          .joins(:factions)
          .joins('JOIN user_factions ON user_factions.faction_id = factions.id')
          .where('user_factions.user_id = ?', params[:user_id])
          .distinct
    }
  end

  def user_factions
    where = { user_id: params[:user_id] }
    where['factions.game_system_id'] = Array.wrap(params[:game_system_id]) if params.key?(:game_system_id)

    render status: 200, json: {
      status: 200,
      user_factions:
        ::UserFaction
          .joins(:faction)
          .select([
            'factions.name as faction_name',
            'COALESCE(NULLIF(user_factions.name, \'\'), factions.name) AS coalesced_name',
            'user_factions.*'
          ])
          .where(where)
          .order('coalesced_name ASC')
          .map(&:attributes)
    }
  end

  def user_models
    where = { user_id: params[:user_id] }
    where['user_models.user_faction_id'] = Array.wrap(params[:user_faction_id]) if params.key?(:user_faction_id)
    where['user_models.id'] = params[:user_model_ids].split(',') if params.key?(:user_model_ids)
    render status: 200, json: {
      status: 200,
      user_models:
        ::UserModel
          .joins(:model)
          .select([
            'models.name as model_name',
            'COALESCE(NULLIF(user_models.name, \'\'), models.name) AS coalesced_name',
            'user_models.*'
          ])
          .where(where)
          .order('coalesced_name ASC')
          .map(&method(:user_model_data))
    }
  end

  def user_model_data(user_model)
    user_model.attributes.merge(
      num_images: user_model.user_image_associations.count
    )
  end

end
