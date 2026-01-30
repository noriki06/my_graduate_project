class RenameDeadlineToTargetDateInWants < ActiveRecord::Migration[7.2]
  def change
    rename_column :wants, :deadline, :target_date
  end
end
