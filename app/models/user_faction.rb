# == Schema Information
#
# Table name: user_factions
#
#  id         :bigint           not null, primary key
#  name       :string
#  notes      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  faction_id :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_factions_on_faction_id  (faction_id)
#  index_user_factions_on_user_id     (user_id)
#
class UserFaction < ApplicationRecord
  belongs_to :user
  belongs_to :faction
  has_many :user_model_groups, dependent: :destroy
  has_many :user_models, dependent: :destroy
  has_many :user_image_associations, dependent: :destroy
  has_many :user_images, through: :user_image_associations
end
