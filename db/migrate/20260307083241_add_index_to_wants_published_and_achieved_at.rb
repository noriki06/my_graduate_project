class AddIndexToWantsPublishedAndAchievedAt < ActiveRecord::Migration[7.2]
  def change
    add_index :wants, [:published, :achieved_at],
              name: "index_wants_on_published_and_achieved_at"
  end
end
