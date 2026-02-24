class CreateDailyActionSuggestions < ActiveRecord::Migration[7.2]
  def change
    create_table :daily_action_suggestions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :want, null: false, foreign_key: true
      t.text :suggested_action, null: false
      t.date :suggested_on, null: false
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :daily_action_suggestions, [ :user_id, :suggested_on ], unique: true
  end
end
