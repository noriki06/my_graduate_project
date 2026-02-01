class AddAchievedAtToWants < ActiveRecord::Migration[7.2]
  def change
    add_column :wants, :achieved_at, :datetime
  end
end
