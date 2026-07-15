class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'citext'

    create_table :accounts, id: :uuid, default: 'uuidv7()' do |t|
      t.text :name, null: false
      t.citext :email_address, null: false
      t.text :password_digest, null: false

      t.timestamps
    end
    add_index :accounts, :email_address, unique: true
  end
end
