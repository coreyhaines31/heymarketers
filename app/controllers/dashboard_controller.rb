class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @timeframe = parse_timeframe(params[:timeframe] || '7_days')

    if current_user.marketer?
      render_marketer_dashboard
    elsif current_user.employer?
      render_employer_dashboard
    else
      render_general_dashboard
    end
  end

  def analytics
    @timeframe = parse_timeframe(params[:timeframe] || '30_days')
    @daily_stats = AnalyticsEvent.daily_stats(days: timeframe_days(@timeframe))

    @total_events = AnalyticsEvent.where(created_at: @timeframe).count
    @unique_users = AnalyticsEvent.where(created_at: @timeframe).distinct.count(:user_id)
    @popular_profiles = AnalyticsEvent.popular_profiles(timeframe: @timeframe)
    @popular_jobs = AnalyticsEvent.popular_jobs(timeframe: @timeframe)

    @event_breakdown = AnalyticsEvent.where(created_at: @timeframe)
                                   .group(:event_type)
                                   .count
                                   .sort_by { |_, count| -count }
  end

  def profile_stats
    return redirect_to dashboard_path unless current_user.marketer?

    @marketer_profile = current_user.accounts.joins(:marketer_profile).first&.marketer_profile
    return redirect_to new_marketer_profile_path unless @marketer_profile

    @timeframe = parse_timeframe(params[:timeframe] || '30_days')

    # Profile views analytics
    @profile_views = AnalyticsEvent.where(
      trackable: @marketer_profile,
      event_type: 'profile_view',
      created_at: @timeframe
    )

    @total_views = @profile_views.count
    @unique_visitors = @profile_views.distinct.count(:user_id)
    @daily_views = @profile_views.group_by_day(:created_at).count

    # Contact analytics
    @messages_received = @marketer_profile.messages.where(created_at: @timeframe).count
    @contact_conversion_rate = @total_views > 0 ? (@messages_received.to_f / @total_views * 100).round(1) : 0

    # Review analytics
    @reviews_received = @marketer_profile.reviews.where(created_at: @timeframe).count
    @average_rating = @marketer_profile.average_rating
    @total_reviews = @marketer_profile.total_reviews

    # Traffic sources
    @traffic_sources = @profile_views.where.not(referrer: nil)
                                   .group(:referrer)
                                   .count
                                   .sort_by { |_, count| -count }
                                   .first(10)

    # Device analytics
    @device_breakdown = @profile_views.joins('LEFT JOIN analytics_events ae2 ON ae2.id = analytics_events.id')
                                     .select('CASE
                                              WHEN user_agent ILIKE \'%Mobile%\' OR user_agent ILIKE \'%Android%\' OR user_agent ILIKE \'%iPhone%\' THEN \'Mobile\'
                                              WHEN user_agent ILIKE \'%iPad%\' OR user_agent ILIKE \'%Tablet%\' THEN \'Tablet\'
                                              ELSE \'Desktop\'
                                              END as device_type')
                                     .group('device_type')
                                     .count
  end

  def job_stats
    return redirect_to dashboard_path unless current_user.employer?

    @company_profile = current_user.accounts.joins(:company_profile).first&.company_profile
    return redirect_to new_company_profile_path unless @company_profile

    @timeframe = parse_timeframe(params[:timeframe] || '30_days')

    # Job performance
    @job_listings = @company_profile.job_listings.includes(:analytics_events)
    @active_jobs = @job_listings.active
    @total_job_views = AnalyticsEvent.where(
      trackable_type: 'JobListing',
      trackable_id: @job_listings.pluck(:id),
      event_type: 'job_view',
      created_at: @timeframe
    ).count

    # Job analytics per listing
    @job_performance = @job_listings.map do |job|
      views = AnalyticsEvent.where(
        trackable: job,
        event_type: 'job_view',
        created_at: @timeframe
      ).count

      applications = AnalyticsEvent.where(
        trackable: job,
        event_type: 'job_apply',
        created_at: @timeframe
      ).count

      {
        job: job,
        views: views,
        applications: applications,
        conversion_rate: views > 0 ? (applications.to_f / views * 100).round(1) : 0
      }
    end.sort_by { |stat| -stat[:views] }

    # Trending metrics
    @daily_job_views = AnalyticsEvent.where(
      trackable_type: 'JobListing',
      trackable_id: @job_listings.pluck(:id),
      event_type: 'job_view',
      created_at: @timeframe
    ).group_by_day(:created_at).count
  end

  private

  def render_marketer_dashboard
    @marketer_profile = current_user.accounts.joins(:marketer_profile).first&.marketer_profile

    if @marketer_profile
      @profile_views_today = AnalyticsEvent.where(
        trackable: @marketer_profile,
        event_type: 'profile_view'
      ).today.count

      @profile_views_this_week = AnalyticsEvent.where(
        trackable: @marketer_profile,
        event_type: 'profile_view'
      ).this_week.count

      @messages_this_week = @marketer_profile.messages.where(created_at: 1.week.ago..Time.current).count
      @reviews_this_month = @marketer_profile.reviews.where(created_at: 1.month.ago..Time.current).count

      @recent_activity = AnalyticsEvent.where(trackable: @marketer_profile)
                                      .recent
                                      .limit(10)
                                      .includes(:user)
    end

    @unread_notifications = current_user.unread_notifications_count
    @unread_messages = current_user.sent_messages.where(read_at: nil).count

    render 'index_marketer'
  end

  def render_employer_dashboard
    @company_profile = current_user.accounts.joins(:company_profile).first&.company_profile

    if @company_profile
      @active_jobs_count = @company_profile.job_listings.active.count
      @total_job_views_today = AnalyticsEvent.where(
        trackable_type: 'JobListing',
        trackable_id: @company_profile.job_listings.pluck(:id),
        event_type: 'job_view'
      ).today.count

      @total_job_views_this_week = AnalyticsEvent.where(
        trackable_type: 'JobListing',
        trackable_id: @company_profile.job_listings.pluck(:id),
        event_type: 'job_view'
      ).this_week.count

      @recent_job_activity = AnalyticsEvent.where(
        trackable_type: 'JobListing',
        trackable_id: @company_profile.job_listings.pluck(:id)
      ).recent.limit(10).includes(:user, :trackable)
    end

    render 'index_employer'
  end

  def render_general_dashboard
    @total_marketers = MarketerProfile.count
    @total_jobs = JobListing.active.count
    @total_reviews = Review.active.count

    render 'index_general'
  end

  def parse_timeframe(timeframe_param)
    case timeframe_param
    when '24_hours'
      24.hours.ago..Time.current
    when '7_days'
      7.days.ago..Time.current
    when '30_days'
      30.days.ago..Time.current
    when '90_days'
      90.days.ago..Time.current
    else
      7.days.ago..Time.current
    end
  end

  def timeframe_days(timeframe)
    ((timeframe.end - timeframe.begin) / 1.day).to_i
  end
end
