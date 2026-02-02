class AddAchievementNoteToWants < ActiveRecord::Migration[7.2]
  def change
    add_column :wants, :achievement_note, :text
  end
end
