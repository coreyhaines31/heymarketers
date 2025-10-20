class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [:show, :mark_as_read]

  def index
    @notifications = current_user.notifications
                                .recent
                                .includes(:actor, :notifiable)
                                .page(params[:page])
                                .per(20)

    @unread_count = current_user.unread_notifications_count

    # Filter by type if specified
    if params[:type].present? && Notification::NOTIFICATION_TYPES.include?(params[:type])
      @notifications = @notifications.by_type(params[:type])
    end

    # Filter by read status
    case params[:status]
    when 'unread'
      @notifications = @notifications.unread
    when 'read'
      @notifications = @notifications.read
    end
  end

  def show
    @notification.mark_as_read! if @notification.unread?

    # Redirect to the action URL if it exists
    if @notification.action_url.present?
      redirect_to @notification.action_url
    else
      redirect_to notifications_path
    end
  end

  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.json { render json: { status: 'success', read: true } }
      format.html { redirect_back(fallback_location: notifications_path) }
    end
  end

  def mark_all_as_read
    current_user.mark_all_notifications_as_read!

    respond_to do |format|
      format.json { render json: { status: 'success', count: 0 } }
      format.html { redirect_to notifications_path, notice: 'All notifications marked as read.' }
    end
  end

  def unread_count
    respond_to do |format|
      format.json { render json: { count: current_user.unread_notifications_count } }
    end
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
