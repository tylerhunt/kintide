class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions, id: :uuid, default: 'uuidv7()' do |t|
      t.references :invitation, null: false, foreign_key: true, type: :uuid,
        index: { unique: true }
      t.references :circle, null: false, foreign_key: true, type: :uuid
      t.text :name, null: false
      t.text :phone_number, null: false
      t.text :token, null: false
      t.datetime :deactivated_at

      t.timestamps

      t.index :token, unique: true
      t.index %i[circle_id phone_number], unique: true
    end
  end
end
