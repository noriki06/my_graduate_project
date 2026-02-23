class AddPublishedToWants < ActiveRecord::Migration[7.2]
  def change
    add_column :wants, :published, :boolean, default: false, null: false
    add_index :wants, :published
  end
end
