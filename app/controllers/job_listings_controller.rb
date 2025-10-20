class JobListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_company_profile, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_job_listing, only: [:show, :edit, :update, :destroy]
  before_action :ensure_company_owner, only: [:new, :create, :edit, :update, :destroy]

  def index
    search_service = JobSearchService.new(search_params)
    search_service.search

    @job_listings = search_service.results
    @total_count = search_service.total_count

    # Load filter options
    @locations = Location.ordered
    @employment_types = JobSearchService::VALID_EMPLOYMENT_TYPES
    @company_sizes = JobSearchService::VALID_COMPANY_SIZES
    @sort_options = JobSearchService::VALID_SORTS
    @posted_within_options = [
      ['Any time', ''],
      ['Last 24 hours', 'day'],
      ['Last week', 'week'],
      ['Last month', 'month']
    ]

    # For filter persistence
    @search_params = search_params
  end

  def show
    # Public job listing view
  end

  def new
    @job_listing = @company_profile.job_listings.build
    @locations = Location.ordered
  end

  def create
    @job_listing = @company_profile.job_listings.build(job_listing_params)

    if @job_listing.save
      redirect_to [@company_profile, @job_listing], notice: 'Job listing created successfully!'
    else
      @locations = Location.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @locations = Location.ordered
  end

  def update
    if @job_listing.update(job_listing_params)
      redirect_to [@company_profile, @job_listing], notice: 'Job listing updated successfully!'
    else
      @locations = Location.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job_listing.destroy
    redirect_to @company_profile, notice: 'Job listing deleted successfully!'
  end

  private

  def set_company_profile
    @company_profile = current_user.accounts.joins(:company_profile).find(params[:company_profile_id]).company_profile
  end

  def set_job_listing
    if params[:company_profile_id]
      @job_listing = @company_profile.job_listings.find(params[:id])
    else
      @job_listing = JobListing.find(params[:id])
    end
  end

  def ensure_company_owner
    unless @company_profile && current_user.accounts.joins(:company_profile).where(company_profiles: { id: @company_profile.id }).exists?
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def job_listing_params
    params.require(:job_listing).permit(:title, :description, :location_id, :employment_type,
                                       :salary_min, :salary_max, :remote_ok, :expires_at)
  end

  def search_params
    params.permit(:query, :location_id, :employment_type, :remote_ok, :min_salary, :max_salary,
                  :posted_within, :company_size, :sort, :page, :per_page, employment_types: [])
  end
end
