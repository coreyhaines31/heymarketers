class MarketerProfilesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_marketer_profile, only: [:show, :edit, :update, :destroy]
  before_action :check_ownership, only: [:edit, :update, :destroy]

  # GET /marketers
  def index
    search_service = MarketerSearchService.new(search_params)
    search_service.search

    @marketer_profiles = search_service.results
    @total_count = search_service.total_count

    # Load filter options
    @skills = Skill.order(:name)
    @locations = Location.order(:name)
    @experience_levels = MarketerSearchService::VALID_EXPERIENCE_LEVELS
    @sort_options = MarketerSearchService::VALID_SORTS
    @availability_options = [
      ['Available for new projects', 'available'],
      ['Available part-time', 'part_time'],
      ['Fully booked', 'booked'],
      ['Not available', 'unavailable']
    ]

    # For filter persistence
    @search_params = search_params
  end

  # GET /marketers/:id
  def show
  end

  # GET /marketer_profiles/new
  def new
    @marketer_profile = current_user.accounts.first&.build_marketer_profile || MarketerProfile.new
    @skills = Skill.order(:name)
    @locations = Location.order(:name)
  end

  # POST /marketer_profiles
  def create
    @account = current_user.accounts.first || create_user_account
    @marketer_profile = @account.build_marketer_profile(marketer_profile_params)

    if @marketer_profile.save
      redirect_to marketer_path(@marketer_profile), notice: 'Marketer profile was successfully created.'
    else
      @skills = Skill.order(:name)
      @locations = Location.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  # GET /marketer_profiles/:id/edit
  def edit
    @skills = Skill.order(:name)
    @locations = Location.order(:name)
  end

  # PATCH/PUT /marketer_profiles/:id
  def update
    if @marketer_profile.update(marketer_profile_params)
      redirect_to marketer_path(@marketer_profile), notice: 'Marketer profile was successfully updated.'
    else
      @skills = Skill.order(:name)
      @locations = Location.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /marketer_profiles/:id
  def destroy
    @marketer_profile.destroy
    redirect_to marketers_path, notice: 'Marketer profile was successfully deleted.'
  end

  private

  def set_marketer_profile
    @marketer_profile = MarketerProfile.find(params[:id])
  end

  def check_ownership
    unless @marketer_profile.account.users.include?(current_user)
      redirect_to marketers_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def marketer_profile_params
    params.require(:marketer_profile).permit(:title, :bio, :hourly_rate, :portfolio_url,
                                            :availability, :location_id, :experience_level,
                                            :resume, :profile_photo, skill_ids: [])
  end

  def search_params
    params.permit(:query, :location_id, :min_rate, :max_rate, :availability,
                  :experience_level, :sort, :page, :per_page, skill_ids: [])
  end

  def create_user_account
    account = Account.create!(name: current_user.full_name)
    Membership.create!(user: current_user, account: account, role: 'owner')
    account
  end
end
