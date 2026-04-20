# app/models/goal.rb
class Goal < ApplicationRecord
  belongs_to :user
  has_many :tasks, dependent: :destroy
end