class CompanyProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company_profile, only: [:show, :edit, :update, :destroy]
  before_action :ensure_owner, only: [:edit, :update, :destroy]

  def index
    @company_profiles = current_user.accounts.joins(:company_profile).includes(:company_profile)
  end

  def new
    @account = Account.new
    @company_profile = @account.build_company_profile
    @locations = Location.ordered
  end

  def create
    @account = Account.new(name: company_profile_params[:name])
    @company_profile = @account.build_company_profile(company_profile_params.except(:name))

    if @account.save
      # Create membership for current user
      current_user.memberships.create!(account: @account, role: 'owner')
      redirect_to @company_profile, notice: 'Company profile created successfully!'
    else
      @locations = Location.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @job_listings = @company_profile.job_listings.active.recent.limit(5)
  end

  def edit
    @locations = Location.ordered
  end

  def update
    if @company_profile.update(company_profile_params.except(:name))
      @company_profile.account.update(name: company_profile_params[:name]) if company_profile_params[:name].present?
      redirect_to @company_profile, notice: 'Company profile updated successfully!'
    else
      @locations = Location.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company_profile.destroy
    redirect_to company_profiles_path, notice: 'Company profile deleted successfully!'
  end

  private

  def set_company_profile
    @company_profile = CompanyProfile.find(params[:id])
  end

  def ensure_owner
    unless current_user.accounts.joins(:company_profile).where(company_profiles: { id: @company_profile.id }).exists?
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
    end
  end

  def company_profile_params
    params.require(:company_profile).permit(:name, :description, :website, :location_id, :logo)
  end
end
