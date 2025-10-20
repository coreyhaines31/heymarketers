class CreateFavorites < ActiveRecord::Migration[7.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :favoritable, polymorphic: true, null: false
      t.text :notes, limit: 1000
      t.boolean :private, default: true, null: false
      t.string :category, limit: 50

      t.timestamps
    end

    # Indexes for efficient querying
    add_index :favorites, [:user_id, :favoritable_type, :favoritable_id],
              unique: true,
              name: "index_favorites_unique_user_favoritable"
    add_index :favorites, [:favoritable_type, :favoritable_id]
    add_index :favorites, [:user_id, :created_at]
    add_index :favorites, [:user_id, :category]
    add_index :favorites, :created_at
  end
end
