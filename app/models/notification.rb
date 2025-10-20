class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User', optional: true
  belongs_to :notifiable, polymorphic: true

  validates :notification_type, presence: true, length: { maximum: 50 }
  validates :title, presence: true, length: { maximum: 255 }
  validates :message, presence: true, length: { maximum: 1000 }
  validates :action_url, length: { maximum: 500 }, allow_blank: true

  # Notification types
  NOTIFICATION_TYPES = [
    'new_message',
    'new_review',
    'review_helpful_vote',
    'profile_view',
    'job_application',
    'job_posted',
    'marketer_contacted',
    'account_activity',
    'system_announcement'
  ].freeze

  validates :notification_type, inclusion: { in: NOTIFICATION_TYPES }

  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(notification_type: type) if type.present? }
  scope :for_recipient, ->(user) { where(recipient: user) }

  # Mark as read
  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end

  def mark_as_unread!
    update!(read_at: nil) if read?
  end

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  # Time helpers
  def time_ago
    case
    when created_at > 1.hour.ago
      "#{((Time.current - created_at) / 1.minute).to_i}m ago"
    when created_at > 1.day.ago
      "#{((Time.current - created_at) / 1.hour).to_i}h ago"
    when created_at > 1.week.ago
      "#{((Time.current - created_at) / 1.day).to_i}d ago"
    else
      created_at.strftime("%b %d")
    end
  end

  # Icon mapping for different notification types
  def icon_class
    case notification_type
    when 'new_message'
      'mail'
    when 'new_review'
      'star'
    when 'review_helpful_vote'
      'thumbs-up'
    when 'profile_view'
      'eye'
    when 'job_application'
      'briefcase'
    when 'job_posted'
      'plus-circle'
    when 'marketer_contacted'
      'user-plus'
    when 'account_activity'
      'activity'
    when 'system_announcement'
      'megaphone'
    else
      'bell'
    end
  end

  # Color mapping for different notification types
  def color_class
    case notification_type
    when 'new_message'
      'text-blue-600'
    when 'new_review'
      'text-yellow-600'
    when 'review_helpful_vote'
      'text-green-600'
    when 'profile_view'
      'text-purple-600'
    when 'job_application', 'job_posted'
      'text-orange-600'
    when 'marketer_contacted'
      'text-indigo-600'
    when 'account_activity'
      'text-gray-600'
    when 'system_announcement'
      'text-red-600'
    else
      'text-blue-600'
    end
  end

  # Class methods for creating notifications
  class << self
    def create_for_new_message(message)
      return unless message.recipient

      create!(
        recipient: message.recipient,
        actor: message.sender,
        notifiable: message,
        notification_type: 'new_message',
        title: "New message from #{message.sender.account&.name || message.sender.email}",
        message: "You have received a new message: \"#{message.content.truncate(50)}\"",
        action_url: "/messages/#{message.id}",
        metadata: {
          marketer_profile_id: message.marketer_profile&.id
        }
      )
    end

    def create_for_new_review(review)
      return unless review.reviewee

      create!(
        recipient: review.reviewee,
        actor: review.reviewer,
        notifiable: review,
        notification_type: 'new_review',
        title: "New #{review.rating}-star review received",
        message: "#{review.display_reviewer_name} left you a review: \"#{review.title}\"",
        action_url: "/marketer_profiles/#{review.marketer_profile.id}/reviews/#{review.id}",
        metadata: {
          rating: review.rating,
          marketer_profile_id: review.marketer_profile.id
        }
      )
    end

    def create_for_helpful_vote(review, voter)
      return unless review.reviewee != voter

      create!(
        recipient: review.reviewer,
        actor: voter,
        notifiable: review,
        notification_type: 'review_helpful_vote',
        title: "Someone found your review helpful",
        message: "Your review \"#{review.title}\" was marked as helpful",
        action_url: "/marketer_profiles/#{review.marketer_profile.id}/reviews/#{review.id}",
        metadata: {
          marketer_profile_id: review.marketer_profile.id,
          review_id: review.id
        }
      )
    end

    def create_for_profile_view(marketer_profile, viewer)
      return unless marketer_profile.account.users.present? && viewer
      return if marketer_profile.account.users.include?(viewer) # Don't notify for own profile views

      recipient = marketer_profile.account.users.first

      # Only create notification if there hasn't been one from this viewer in the last 24 hours
      return if where(
        recipient: recipient,
        actor: viewer,
        notification_type: 'profile_view',
        created_at: 24.hours.ago..Time.current
      ).exists?

      create!(
        recipient: recipient,
        actor: viewer,
        notifiable: marketer_profile,
        notification_type: 'profile_view',
        title: "Someone viewed your profile",
        message: "Your marketing profile received a new view",
        action_url: "/marketers/#{marketer_profile.id}",
        metadata: {
          marketer_profile_id: marketer_profile.id
        }
      )
    end

    def mark_all_as_read_for_user(user)
      unread.for_recipient(user).update_all(read_at: Time.current)
    end

    def unread_count_for_user(user)
      unread.for_recipient(user).count
    end
  end
end