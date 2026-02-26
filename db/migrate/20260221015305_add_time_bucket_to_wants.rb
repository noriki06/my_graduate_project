class AddTimeBucketToWants < ActiveRecord::Migration[7.2]
  def change
    add_column :wants, :time_bucket, :string
  end
end
