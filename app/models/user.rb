class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # Relationships will be added here
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :sent_messages, class_name: 'Message', foreign_key: 'sender_id', dependent: :destroy

  # Review relationships
  has_many :written_reviews, class_name: 'Review', foreign_key: 'reviewer_id', dependent: :destroy
  has_many :received_reviews, class_name: 'Review', foreign_key: 'reviewee_id', dependent: :destroy
  has_many :review_helpful_votes, dependent: :destroy

  # Notification relationships
  has_many :notifications, foreign_key: 'recipient_id', dependent: :destroy
  has_many :triggered_notifications, class_name: 'Notification', foreign_key: 'actor_id', dependent: :nullify

  # Analytics relationships
  has_many :analytics_events, dependent: :destroy

  # Favorites relationships
  has_many :favorites, dependent: :destroy
  has_many :favorite_marketer_profiles, -> { where(favoritable_type: 'MarketerProfile') },
           class_name: 'Favorite'
  has_many :favorite_job_listings, -> { where(favoritable_type: 'JobListing') },
           class_name: 'Favorite'

  def marketer?
    accounts.joins(:marketer_profile).exists?
  end

  def employer?
    accounts.joins(:company_profile).exists?
  end

  def full_name
    # Will add first_name and last_name fields later
    email.split('@').first.titleize
  end

  # Notification helper methods
  def unread_notifications_count
    notifications.unread.count
  end

  def recent_notifications(limit = 10)
    notifications.recent.includes(:actor, :notifiable).limit(limit)
  end

  def mark_all_notifications_as_read!
    notifications.unread.update_all(read_at: Time.current)
  end

  # Favorites helper methods
  def has_favorited?(favoritable)
    favorites.exists?(favoritable: favoritable)
  end

  def favorite_for(favoritable)
    favorites.find_by(favoritable: favoritable)
  end

  def toggle_favorite(favoritable, attributes = {})
    Favorite.toggle_favorite(self, favoritable, attributes)
  end

  def favorites_count
    favorites.count
  end

  def favorite_profiles_count
    favorite_marketer_profiles.count
  end

  def favorite_jobs_count
    favorite_job_listings.count
  end
end
