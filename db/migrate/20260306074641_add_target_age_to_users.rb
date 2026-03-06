class AddTargetAgeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :target_age, :integer, default: 84, null: false
  end
end
