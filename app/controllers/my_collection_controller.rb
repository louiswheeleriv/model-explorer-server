class MyCollectionController < ApplicationController
  def index
    redirect_to '/sign_in' unless current_user_id
  end

  def show_faction
    if current_user_id
      @faction = Faction.find_by(name: params[:faction_name])
    else
      redirect_to '/sign_in'
    end
  end

  def add_faction
    faction_id = params[:faction_id]
    faction = ::Faction.find_by(id: faction_id)
    raise 'Faction not found' unless faction

    user_faction = ::UserFaction.find_by(user_id: current_user_id, faction_id: faction_id)
    raise "Faction #{faction.name} is already in your collection" if user_faction

    user_faction = ::UserFaction.create(user_id: current_user_id, faction_id: faction_id)
    render status: 200, json: { status: 200, user_faction: user_faction, faction: faction }
  end

  def add_user_model
    # REQUIRE LOGGED IN

    faction_id = params[:faction_id]
    model_id = params[:model_id]
    quantity_by_status = params[:quantity_by_status]
    faction = ::Faction.find_by(id: faction_id)
    raise "Faction #{faction_id} not found" unless faction

    model = ::Model.find_by(id: model_id)
    raise "Model #{model_id} not found" unless model

    user_model = ::UserModel.create(
      user_id: current_user_id,
      model_id: model_id,
      qty_unassembled: quantity_by_status['unassembled'],
      qty_assembled: quantity_by_status['assembled'],
      qty_in_progress: quantity_by_status['in_progress'],
      qty_finished: quantity_by_status['finished']
    )

    render status: 200, json: { status: 200, user_model: user_model }
  end

  def edit_model
    faction_id = params[:faction_id]
    model_id = params[:model_id]
    quantity_by_status = params[:quantity_by_status]
    faction = ::Faction.find_by(id: faction_id)
    raise "Faction #{faction_id} not found" unless faction

    model = ::Model.find_by(id: model_id)
    raise "Model #{model_id} not found" unless model

    user_model = ::UserModel.find_by(
      user_id: current_user_id,
      model_id: model_id
    )
    raise "UserModel for Model #{model_id} not found" unless user_model

    user_model.update(
      qty_unassembled: quantity_by_status['unassembled'],
      qty_assembled: quantity_by_status['assembled'],
      qty_in_progress: quantity_by_status['in_progress'],
      qty_finished: quantity_by_status['finished']
    )

    render status: 200, json: { status: 200, user_model: user_model }
  end

end
