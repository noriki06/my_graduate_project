class AddLineFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :line_user_id, :string
    add_column :users, :line_link_token, :string

    add_index :users, :line_user_id, unique: true
    add_index :users, :line_link_token, unique: true
  end
end
