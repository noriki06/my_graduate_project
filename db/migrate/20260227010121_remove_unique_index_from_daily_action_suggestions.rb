class RemoveUniqueIndexFromDailyActionSuggestions < ActiveRecord::Migration[7.2]
  def change
    remove_index :daily_action_suggestions, [ :user_id, :suggested_on ]
    add_index :daily_action_suggestions, [ :user_id, :suggested_on ]
  end
end
