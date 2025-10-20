class JobListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_company_profile, only: [:new, :create, :edit, :update, :destroy]
  before_action :set_job_listing, only: [:show, :edit, :update, :destroy]
  before_action :ensure_company_owner, only: [:new, :create, :edit, :update, :destroy]

  def index
    @job_listings = JobListing.active
                              .includes(:company_profile, :location)
                              .recent
                              .page(params[:page])

    # Filter by location if provided
    @job_listings = @job_listings.by_location(params[:location_id]) if params[:location_id].present?

    # Filter by employment type if provided
    @job_listings = @job_listings.by_employment_type(params[:employment_type]) if params[:employment_type].present?

    # Filter by remote-friendly if requested
    @job_listings = @job_listings.remote_friendly if params[:remote_ok] == 'true'

    @locations = Location.ordered
    @employment_types = JobListing.distinct.pluck(:employment_type).compact
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
end
