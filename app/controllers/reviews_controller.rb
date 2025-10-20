class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_marketer_profile, only: [:index, :new, :create]
  before_action :set_review, only: [:show, :edit, :update, :destroy, :vote]
  before_action :ensure_can_review, only: [:new, :create]
  before_action :ensure_review_owner, only: [:edit, :update, :destroy]

  def index
    @reviews = @marketer_profile.reviews.active.includes(:reviewer, :review_helpful_votes).recent
    @average_rating = @marketer_profile.average_rating
    @total_reviews = @marketer_profile.total_reviews
    @rating_distribution = @marketer_profile.rating_distribution
  end

  def show
    @marketer_profile = @review.marketer_profile
  end

  def new
    @review = @marketer_profile.reviews.build(reviewer: current_user, reviewee: @marketer_profile.account.users.first)
  end

  def create
    @review = @marketer_profile.reviews.build(review_params)
    @review.reviewer = current_user
    @review.reviewee = @marketer_profile.account.users.first

    if @review.save
      redirect_to [@marketer_profile, @review], notice: 'Thank you for your review!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @marketer_profile = @review.marketer_profile
  end

  def update
    if @review.update(review_params)
      redirect_to [@review.marketer_profile, @review], notice: 'Review updated successfully!'
    else
      @marketer_profile = @review.marketer_profile
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @marketer_profile = @review.marketer_profile
    @review.destroy
    redirect_to marketer_profile_reviews_path(@marketer_profile), notice: 'Review deleted successfully.'
  end

  def vote
    if @review.helpful_for_user?(current_user)
      # Remove vote
      @review.review_helpful_votes.find_by(user: current_user)&.destroy
      action = 'removed'
    else
      # Add vote
      @review.review_helpful_votes.create(user: current_user)
      action = 'added'
    end

    respond_to do |format|
      format.json do
        render json: {
          helpful_count: @review.reload.helpful_count,
          user_voted: @review.helpful_for_user?(current_user),
          action: action
        }
      end
      format.html { redirect_back(fallback_location: @review) }
    end
  end

  private

  def set_marketer_profile
    @marketer_profile = MarketerProfile.find(params[:marketer_profile_id])
  end

  def set_review
    @review = Review.find(params[:id])
  end

  def ensure_can_review
    unless @marketer_profile.can_be_reviewed_by?(current_user)
      redirect_to @marketer_profile, alert: 'You cannot review this marketer.'
    end
  end

  def ensure_review_owner
    unless @review.reviewer == current_user || current_user.admin?
      redirect_to @review, alert: 'You can only edit your own reviews.'
    end
  end

  def review_params
    params.require(:review).permit(:rating, :title, :content, :anonymous)
  end
end