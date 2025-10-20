class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewee, null: false, foreign_key: { to_table: :users }
      t.references :marketer_profile, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :title, null: false, limit: 100
      t.text :content, null: false
      t.integer :helpful_count, default: 0, null: false
      t.string :status, default: 'active', null: false
      t.boolean :anonymous, default: false, null: false

      t.timestamps
    end

    # Add indexes for performance
    add_index :reviews, [:marketer_profile_id, :status]
    add_index :reviews, [:reviewee_id, :status]
    add_index :reviews, :rating
    add_index :reviews, :created_at

    # Add constraint to ensure rating is between 1 and 5
    add_check_constraint :reviews, "rating >= 1 AND rating <= 5", name: "rating_range_check"

    # Ensure reviewer can't review themselves
    add_check_constraint :reviews, "reviewer_id != reviewee_id", name: "no_self_review_check"

    # Add unique constraint to prevent duplicate reviews from same reviewer for same marketer
    add_index :reviews, [:reviewer_id, :marketer_profile_id], unique: true, name: "unique_reviewer_marketer_review"
  end
end
