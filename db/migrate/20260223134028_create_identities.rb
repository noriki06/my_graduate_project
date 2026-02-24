class CreateIdentities < ActiveRecord::Migration[7.2]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    # 同じSNSアカウントが複数登録されないようにする
    add_index :identities, [ :provider, :uid ], unique: true

    # 同じユーザーが同じproviderを2回登録しないようにする
    add_index :identities, [ :user_id, :provider ], unique: true
  end
end
