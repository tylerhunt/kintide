class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid, default: 'uuidv7()' do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.text :ip_address
      t.text :user_agent

      t.timestamps
    end
  end
end
