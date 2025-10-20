class AnalyticsEvent < ApplicationRecord
  belongs_to :user, optional: true # Allow anonymous tracking
  belongs_to :trackable, polymorphic: true

  validates :event_type, presence: true, length: { maximum: 50 }
  validates :ip_address, length: { maximum: 45 }, allow_blank: true
  validates :session_id, length: { maximum: 128 }, allow_blank: true
  validates :referrer, length: { maximum: 500 }, allow_blank: true
  validates :utm_source, length: { maximum: 100 }, allow_blank: true
  validates :utm_medium, length: { maximum: 100 }, allow_blank: true
  validates :utm_campaign, length: { maximum: 100 }, allow_blank: true

  # Event types for tracking
  EVENT_TYPES = [
    # Profile interactions
    'profile_view',
    'profile_contact',
    'profile_share',

    # Job interactions
    'job_view',
    'job_apply',
    'job_share',
    'job_save',

    # Review interactions
    'review_create',
    'review_view',
    'review_helpful_vote',

    # Message interactions
    'message_send',
    'message_read',

    # Search interactions
    'search_perform',
    'search_filter',
    'search_result_click',

    # Engagement
    'page_view',
    'session_start',
    'session_end',
    'signup',
    'login',
    'logout'
  ].freeze

  validates :event_type, inclusion: { in: EVENT_TYPES }

  # Scopes for analytics queries
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) if type.present? }
  scope :by_user, ->(user) { where(user: user) if user.present? }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) if trackable.present? }
  scope :in_timeframe, ->(start_time, end_time) { where(created_at: start_time..end_time) }
  scope :today, -> { where(created_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(created_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(created_at: 1.month.ago..Time.current) }

  # Class methods for creating events
  class << self
    def track_profile_view(marketer_profile, user: nil, request: nil)
      create_event(
        trackable: marketer_profile,
        event_type: 'profile_view',
        user: user,
        request: request,
        properties: {
          marketer_profile_id: marketer_profile.id,
          title: marketer_profile.title,
          location: marketer_profile.location&.name,
          hourly_rate: marketer_profile.hourly_rate
        }
      )
    end

    def track_job_view(job_listing, user: nil, request: nil)
      create_event(
        trackable: job_listing,
        event_type: 'job_view',
        user: user,
        request: request,
        properties: {
          job_listing_id: job_listing.id,
          title: job_listing.title,
          company: job_listing.company_profile.name,
          employment_type: job_listing.employment_type,
          location: job_listing.location&.name,
          remote_ok: job_listing.remote_ok
        }
      )
    end

    def track_search(query: nil, filters: {}, results_count: 0, user: nil, request: nil)
      create_event(
        trackable: User.first, # Placeholder trackable for search events
        event_type: 'search_perform',
        user: user,
        request: request,
        properties: {
          query: query,
          filters: filters,
          results_count: results_count,
          has_results: results_count > 0
        }
      )
    end

    def track_message_send(message, user: nil, request: nil)
      create_event(
        trackable: message,
        event_type: 'message_send',
        user: user,
        request: request,
        properties: {
          recipient_id: message.recipient&.id,
          marketer_profile_id: message.marketer_profile&.id,
          content_length: message.content&.length || 0
        }
      )
    end

    def track_review_create(review, user: nil, request: nil)
      create_event(
        trackable: review,
        event_type: 'review_create',
        user: user,
        request: request,
        properties: {
          marketer_profile_id: review.marketer_profile.id,
          rating: review.rating,
          content_length: review.content&.length || 0,
          anonymous: review.anonymous?
        }
      )
    end

    def track_signup(user, request: nil)
      create_event(
        trackable: user,
        event_type: 'signup',
        user: user,
        request: request,
        properties: {
          user_type: user.marketer? ? 'marketer' : 'company'
        }
      )
    end

    def track_login(user, request: nil)
      create_event(
        trackable: user,
        event_type: 'login',
        user: user,
        request: request,
        properties: {
          user_type: user.marketer? ? 'marketer' : 'company'
        }
      )
    end

    # Analytics aggregation methods
    def popular_profiles(limit: 10, timeframe: 1.week.ago..Time.current)
      joins("JOIN marketer_profiles ON trackable_type = 'MarketerProfile' AND trackable_id = marketer_profiles.id")
        .where(event_type: 'profile_view', created_at: timeframe)
        .group('marketer_profiles.id')
        .order('COUNT(*) DESC')
        .limit(limit)
        .pluck('marketer_profiles.id, COUNT(*) as view_count')
    end

    def popular_jobs(limit: 10, timeframe: 1.week.ago..Time.current)
      joins("JOIN job_listings ON trackable_type = 'JobListing' AND trackable_id = job_listings.id")
        .where(event_type: 'job_view', created_at: timeframe)
        .group('job_listings.id')
        .order('COUNT(*) DESC')
        .limit(limit)
        .pluck('job_listings.id, COUNT(*) as view_count')
    end

    def daily_stats(days: 7)
      end_date = Date.current
      start_date = end_date - days.days

      (start_date..end_date).map do |date|
        {
          date: date,
          total_events: where(created_at: date.beginning_of_day..date.end_of_day).count,
          profile_views: where(event_type: 'profile_view', created_at: date.beginning_of_day..date.end_of_day).count,
          job_views: where(event_type: 'job_view', created_at: date.beginning_of_day..date.end_of_day).count,
          searches: where(event_type: 'search_perform', created_at: date.beginning_of_day..date.end_of_day).count
        }
      end
    end

    private

    def create_event(trackable:, event_type:, user: nil, request: nil, properties: {})
      attributes = {
        trackable: trackable,
        event_type: event_type,
        user: user,
        properties: properties
      }

      if request
        attributes.merge!(
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          session_id: request.session.id.to_s,
          referrer: request.referer,
          utm_source: request.params['utm_source'],
          utm_medium: request.params['utm_medium'],
          utm_campaign: request.params['utm_campaign']
        )
      end

      create!(attributes)
    rescue => e
      Rails.logger.error "Failed to create analytics event: #{e.message}"
      nil
    end
  end

  # Instance methods
  def duration_since_previous
    return nil unless user

    previous_event = self.class.where(user: user)
                              .where('created_at < ?', created_at)
                              .order(created_at: :desc)
                              .first

    return nil unless previous_event

    created_at - previous_event.created_at
  end

  def from_utm_campaign?
    utm_source.present? || utm_medium.present? || utm_campaign.present?
  end

  def mobile_device?
    return false unless user_agent

    user_agent.match?(/Mobile|Android|iPhone|iPad/i)
  end
end