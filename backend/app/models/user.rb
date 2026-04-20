# app/models/user.rb
class User < ApplicationRecord
  has_many :goals, dependent: :destroy
end