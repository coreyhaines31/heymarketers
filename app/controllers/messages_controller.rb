class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_marketer_profile, only: [:new, :create]
  before_action :set_message, only: [:show, :mark_as_read]

  def new
    @message = @marketer_profile.messages.build
    @message.subject = params[:subject] if params[:subject].present?
  end

  def create
    @message = @marketer_profile.messages.build(message_params)
    @message.sender = current_user

    if @message.save
      redirect_to marketer_path(@marketer_profile), notice: 'Message sent successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # Show individual message (for marketers to read their messages)
    @message.mark_as_read! if can_read_message?
  end

  def index
    # Show all messages for the current user
    if current_user.marketer?
      # Show messages received by marketers
      @received_messages = Message.joins(:marketer_profile)
                                  .where(marketer_profiles: { account_id: current_user.account_ids })
                                  .includes(:sender, :marketer_profile)
                                  .recent
                                  .page(params[:page])
    end

    # Show messages sent by this user
    @sent_messages = current_user.sent_messages
                                 .includes(:marketer_profile)
                                 .recent
                                 .page(params[:page])
  end

  def mark_as_read
    @message.mark_as_read! if can_read_message?
    redirect_back(fallback_location: messages_path)
  end

  private

  def set_marketer_profile
    @marketer_profile = MarketerProfile.find(params[:marketer_profile_id])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:subject, :body)
  end

  def can_read_message?
    # Marketers can read messages sent to their profiles
    # Senders can read their own sent messages
    @message.sender == current_user ||
    current_user.accounts.joins(:marketer_profile).where(marketer_profiles: { id: @message.marketer_profile_id }).exists?
  end
end
