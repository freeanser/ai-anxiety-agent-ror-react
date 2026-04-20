class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email
      t.string :firebase_uid
      t.string :name

      t.timestamps
    end
    add_index :users, :email
    add_index :users, :firebase_uid
  end
end
