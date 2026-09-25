class CreateUsers < ActiveRecord::Migration[8.1]
  # HR users who sign in to the app (single role: HR Manager).
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 100
      t.string :email, null: false, limit: 255
      t.string :password_digest, null: false
      t.timestamps
    end

    # Login lookup; emails are normalized to lower case by the model.
    add_index :users, :email, unique: true
  end
end
