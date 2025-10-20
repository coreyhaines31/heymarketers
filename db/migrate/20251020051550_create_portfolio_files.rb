class CreatePortfolioFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :portfolio_files do |t|
      t.references :marketer_profile, null: false, foreign_key: true
      t.string :title, null: false, limit: 200
      t.text :description, limit: 1000
      t.string :file_type, null: false, limit: 50
      t.bigint :file_size, null: false
      t.string :content_type, null: false, limit: 100
      t.integer :display_order, default: 0, null: false
      t.boolean :is_public, default: true, null: false
      t.string :url, limit: 500
      t.json :metadata, default: {}

      t.timestamps
    end

    # Indexes for efficient querying
    add_index :portfolio_files, [:marketer_profile_id, :display_order]
    add_index :portfolio_files, [:marketer_profile_id, :is_public]
    add_index :portfolio_files, :file_type
    add_index :portfolio_files, :created_at

    # Ensure unique display order per marketer profile
    add_index :portfolio_files, [:marketer_profile_id, :display_order],
              unique: true,
              name: "index_portfolio_files_unique_order"
  end
end
