class CreateWants < ActiveRecord::Migration[7.2]
  def change
    create_table :wants do |t|
      t.string :title
      t.text :memo
      t.date :deadline
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
