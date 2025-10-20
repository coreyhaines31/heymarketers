class CreateReviewHelpfulVotes < ActiveRecord::Migration[7.1]
  def change
    create_table :review_helpful_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :review, null: false, foreign_key: true

      t.timestamps
    end

    # Ensure a user can only vote once per review
    add_index :review_helpful_votes, [:user_id, :review_id], unique: true, name: "unique_user_review_vote"
  end
end
