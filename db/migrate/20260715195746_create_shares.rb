class CreateShares < ActiveRecord::Migration[8.1]
  def change
    create_table :shares, id: :uuid, default: 'uuidv7()' do |t|
      t.references :post, null: false, foreign_key: true, type: :uuid
      t.references :subscription, null: false, foreign_key: true,
        type: :uuid
      t.text :token, null: false
      t.datetime :delivered_at

      t.timestamps

      t.index :token, unique: true
      t.index %i[post_id subscription_id], unique: true
    end
  end
end
