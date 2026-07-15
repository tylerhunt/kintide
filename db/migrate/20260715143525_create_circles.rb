class CreateCircles < ActiveRecord::Migration[8.1]
  def change
    create_table :circles, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid,
        index: { unique: true }
      t.string :name, null: false

      t.timestamps
    end

    # every account owns exactly one circle; backfill existing accounts
    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          INSERT INTO circles (id, account_id, name, created_at, updated_at)
          SELECT gen_random_uuid(), id, name || '''s Circle', NOW(), NOW()
          FROM accounts
        SQL
      end
    end
  end
end
