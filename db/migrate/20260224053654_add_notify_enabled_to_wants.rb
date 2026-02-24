class AddNotifyEnabledToWants < ActiveRecord::Migration[7.2]
  def change
    add_column :wants, :notify_enabled, :boolean, default: true, null: false
  end
end
