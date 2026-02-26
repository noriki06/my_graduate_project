class AddNotificationSettingsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :notification_enabled, :boolean, default: true, null: false
    add_column :users, :notification_frequency, :string, default: "daily", null: false
    add_column :users, :notification_hour, :integer, default: 9, null: false
    add_column :users, :notification_day_of_week, :integer, default: 1, null: false
  end
end
