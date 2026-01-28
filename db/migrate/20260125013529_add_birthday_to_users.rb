class AddBirthdayToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :birthday, :date
  end
end
