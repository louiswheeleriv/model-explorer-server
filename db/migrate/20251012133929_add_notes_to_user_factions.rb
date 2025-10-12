class AddNotesToUserFactions < ActiveRecord::Migration[7.1]
  def change
    add_column :user_factions, :notes, :text
  end
end
