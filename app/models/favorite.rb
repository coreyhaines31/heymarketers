class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :favoritable, polymorphic: true

  validates :user_id, uniqueness: { scope: [:favoritable_type, :favoritable_id],
                                   message: "has already favorited this item" }
  validates :notes, length: { maximum: 1000 }, allow_blank: true
  validates :category, length: { maximum: 50 }, allow_blank: true

  # Categories for organizing favorites
  CATEGORIES = [
    'potential_hire',
    'top_candidate',
    'follow_up',
    'backup_option',
    'inspiration',
    'research',
    'archive'
  ].freeze

  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :profiles, -> { where(favoritable_type: 'MarketerProfile') }
  scope :jobs, -> { where(favoritable_type: 'JobListing') }
  scope :public_favorites, -> { where(private: false) }
  scope :private_favorites, -> { where(private: true) }

  # Analytics tracking
  after_create :track_favorite_creation
  after_destroy :track_favorite_removal

  # Instance methods
  def favoritable_title
    case favoritable_type
    when 'MarketerProfile'
      favoritable.account.name
    when 'JobListing'
      favoritable.title
    else
      'Unknown'
    end
  end

  def favoritable_subtitle
    case favoritable_type
    when 'MarketerProfile'
      favoritable.title
    when 'JobListing'
      favoritable.company_profile.name
    else
      ''
    end
  end

  def favoritable_path
    case favoritable_type
    when 'MarketerProfile'
      Rails.application.routes.url_helpers.marketer_path(favoritable)
    when 'JobListing'
      Rails.application.routes.url_helpers.job_path(favoritable)
    else
      '#'
    end
  end

  def category_display
    category&.humanize || 'Uncategorized'
  end

  def category_color
    case category
    when 'potential_hire'
      'green'
    when 'top_candidate'
      'blue'
    when 'follow_up'
      'yellow'
    when 'backup_option'
      'gray'
    when 'inspiration'
      'purple'
    when 'research'
      'orange'
    when 'archive'
      'red'
    else
      'gray'
    end
  end

  # Class methods
  class << self
    def for_user_and_favoritable(user, favoritable)
      find_by(user: user, favoritable: favoritable)
    end

    def favorited_by?(user, favoritable)
      exists?(user: user, favoritable: favoritable)
    end

    def toggle_favorite(user, favoritable, attributes = {})
      existing_favorite = for_user_and_favoritable(user, favoritable)

      if existing_favorite
        existing_favorite.destroy
        { action: 'removed', favorite: nil }
      else
        favorite = create!(
          user: user,
          favoritable: favoritable,
          **attributes
        )
        { action: 'added', favorite: favorite }
      end
    rescue ActiveRecord::RecordInvalid => e
      { action: 'error', error: e.message }
    end

    def popular_marketers(limit: 10, timeframe: 1.month.ago..Time.current)
      profiles
        .joins("JOIN marketer_profiles ON favoritable_id = marketer_profiles.id")
        .where(created_at: timeframe)
        .group('marketer_profiles.id')
        .order('COUNT(*) DESC')
        .limit(limit)
        .pluck('marketer_profiles.id, COUNT(*) as favorite_count')
    end

    def popular_jobs(limit: 10, timeframe: 1.month.ago..Time.current)
      jobs
        .joins("JOIN job_listings ON favoritable_id = job_listings.id")
        .where(created_at: timeframe)
        .group('job_listings.id')
        .order('COUNT(*) DESC')
        .limit(limit)
        .pluck('job_listings.id, COUNT(*) as favorite_count')
    end

    def category_stats_for_user(user)
      where(user: user)
        .group(:category)
        .count
        .transform_keys { |k| k || 'uncategorized' }
    end
  end

  private

  def track_favorite_creation
    AnalyticsEvent.create!(
      user: user,
      trackable: favoritable,
      event_type: favoritable_type == 'MarketerProfile' ? 'profile_save' : 'job_save',
      properties: {
        category: category,
        favoritable_type: favoritable_type,
        favoritable_id: favoritable_id
      }
    )
  rescue => e
    Rails.logger.error "Failed to track favorite creation: #{e.message}"
  end

  def track_favorite_removal
    AnalyticsEvent.create!(
      user: user,
      trackable: favoritable,
      event_type: favoritable_type == 'MarketerProfile' ? 'profile_unsave' : 'job_unsave',
      properties: {
        category: category,
        favoritable_type: favoritable_type,
        favoritable_id: favoritable_id
      }
    )
  rescue => e
    Rails.logger.error "Failed to track favorite removal: #{e.message}"
  end
end