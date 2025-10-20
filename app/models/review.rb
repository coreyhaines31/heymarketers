class Review < ApplicationRecord
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewee, class_name: 'User'
  belongs_to :marketer_profile
  has_many :review_helpful_votes, dependent: :destroy

  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :content, presence: true, length: { minimum: 20, maximum: 2000 }
  validates :status, inclusion: { in: %w[active flagged hidden] }
  validates :reviewer_id, uniqueness: { scope: :marketer_profile_id, message: "can only review each marketer once" }

  validate :reviewer_cannot_review_self
  validate :reviewer_can_review_marketer

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_rating, ->(rating) { where(rating: rating) if rating.present? }
  scope :helpful, -> { order(helpful_count: :desc) }

  before_save :update_helpful_count
  after_create :create_review_notification

  def self.average_rating
    active.average(:rating)&.round(1) || 0.0
  end

  def self.rating_distribution
    active.group(:rating).count
  end

  def helpful_percentage
    return 0 if review_helpful_votes.count == 0
    ((helpful_count.to_f / review_helpful_votes.count) * 100).round(1)
  end

  def helpful_for_user?(user)
    return false unless user
    review_helpful_votes.exists?(user: user)
  end

  def display_reviewer_name
    if anonymous?
      "Anonymous User"
    else
      reviewer.account&.name || reviewer.email.split('@').first.capitalize
    end
  end

  def reviewer_initials
    if anonymous?
      "AU"
    else
      name = reviewer.account&.name || reviewer.email.split('@').first
      name.split(' ').map(&:first).join.upcase.first(2)
    end
  end

  def time_ago
    case
    when created_at > 1.week.ago
      "#{((Time.current - created_at) / 1.day).to_i} days ago"
    when created_at > 1.month.ago
      "#{((Time.current - created_at) / 1.week).to_i} weeks ago"
    else
      created_at.strftime("%B %Y")
    end
  end

  def verified_client?
    # TODO: Implement verification logic based on actual work relationship
    # For now, return true if reviewer has an account
    reviewer.account.present?
  end

  private

  def reviewer_cannot_review_self
    if reviewer_id == reviewee_id
      errors.add(:reviewer, "cannot review themselves")
    end
  end

  def reviewer_can_review_marketer
    # Ensure the reviewee owns the marketer profile being reviewed
    unless marketer_profile&.account&.users&.include?(reviewee)
      errors.add(:marketer_profile, "does not belong to the reviewee")
    end
  end

  def update_helpful_count
    self.helpful_count = review_helpful_votes.count
  end

  def create_review_notification
    Notification.create_for_new_review(self)
  end
end