class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts, id: :uuid, default: 'uuidv7()' do |t|
      t.references :circle, null: false, foreign_key: true, type: :uuid
      t.text :body, null: false

      t.timestamps
    end
  end
end
