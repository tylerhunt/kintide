class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_enum :subscription_states, %w[invited active deactivated]

    create_table :subscriptions, id: :uuid, default: 'uuidv7()' do |t|
      t.references :circle, null: false, foreign_key: true, type: :uuid
      t.text :name, null: false
      t.text :phone_number, null: false
      t.text :token, null: false
      t.enum :state, enum_type: :subscription_states, default: 'invited',
        null: false
      t.datetime :accepted_at
      t.datetime :deactivated_at

      t.timestamps

      t.index :token, unique: true
      t.index %i[circle_id phone_number], unique: true
    end
  end
end
