class CreateGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :goals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :domain
      t.string :risk_level
      t.text :description

      t.timestamps
    end
  end
end
