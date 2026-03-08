class AllowNullNotificationDayOfWeek < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :notification_day_of_week, true
  end
end
