class ChangeNotifyEnabledDefaultOnWants < ActiveRecord::Migration[7.2]
  def up
    change_column_default :wants, :notify_enabled, from: true, to: false
  end

  def down
    change_column_default :wants, :notify_enabled, from: false, to: true
  end
end
