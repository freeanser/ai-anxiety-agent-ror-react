# app/models/task.rb
class Task < ApplicationRecord
  belongs_to :goal
end