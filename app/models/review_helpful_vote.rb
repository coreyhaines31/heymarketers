class ReviewHelpfulVote < ApplicationRecord
  belongs_to :user
  belongs_to :review

  validates :user_id, uniqueness: { scope: :review_id, message: "can only vote once per review" }

  after_create :increment_helpful_count, :create_helpful_notification
  after_destroy :decrement_helpful_count

  private

  def increment_helpful_count
    review.increment!(:helpful_count)
  end

  def decrement_helpful_count
    review.decrement!(:helpful_count)
  end

  def create_helpful_notification
    Notification.create_for_helpful_vote(review, user)
  end
end