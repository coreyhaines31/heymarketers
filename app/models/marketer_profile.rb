class MarketerProfile < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true

  has_many :marketer_skills, dependent: :destroy
  has_many :skills, through: :marketer_skills
  has_many :marketer_tools, dependent: :destroy
  has_many :tools, through: :marketer_tools
  has_many :messages, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :analytics_events, as: :trackable, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy

  has_one_attached :resume
  has_one_attached :profile_photo

  validates :title, presence: true
  validates :bio, presence: true
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }
  validates :experience_level, inclusion: { in: %w[junior mid senior expert], allow_blank: true }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" }
  validate :slug_not_reserved

  before_validation :generate_slug, if: -> { slug.blank? }
  before_validation :ensure_slug_uniqueness, if: -> { slug_changed? }

  scope :available, -> { where(availability: 'available') }
  scope :by_location, ->(location_id) { where(location_id: location_id) if location_id.present? }
  scope :by_rate_range, ->(min_rate, max_rate) do
    scope = all
    scope = scope.where('hourly_rate >= ?', min_rate) if min_rate.present?
    scope = scope.where('hourly_rate <= ?', max_rate) if max_rate.present?
    scope
  end
  scope :by_experience_level, ->(level) { where(experience_level: level) if level.present? }
  scope :with_skills, ->(skill_ids) do
    skill_ids = Array(skill_ids).reject(&:blank?)
    joins(:skills).where(skills: { id: skill_ids }).distinct if skill_ids.any?
  end

  # Search functionality
  def self.search(query)
    return all if query.blank?

    sanitized_query = query.gsub(/[^\w\s]/, ' ').strip.squeeze(' ')
    where("search_vector @@ plainto_tsquery('english', ?)", sanitized_query)
  end

  def self.search_with_rank(query)
    return all if query.blank?

    sanitized_query = query.gsub(/[^\w\s]/, ' ').strip.squeeze(' ')
    where("search_vector @@ plainto_tsquery('english', ?)", sanitized_query)
      .order("ts_rank(search_vector, plainto_tsquery('english', ?)) DESC", sanitized_query)
  end

  def display_rate
    "$#{hourly_rate}/hr"
  end

  def to_param
    slug
  end

  def experience_level_display
    experience_level&.humanize || 'Not specified'
  end

  # Review and rating methods
  def average_rating
    reviews.active.average(:rating)&.round(1) || 0.0
  end

  def total_reviews
    reviews.active.count
  end

  def rating_distribution
    reviews.active.group(:rating).count.reverse_merge(
      1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0
    ).sort
  end

  def rating_percentage(rating)
    return 0 if total_reviews == 0
    count = reviews.active.where(rating: rating).count
    ((count.to_f / total_reviews) * 100).round(1)
  end

  def display_rating
    if total_reviews > 0
      "#{average_rating} (#{total_reviews} review#{'s' if total_reviews != 1})"
    else
      "No reviews yet"
    end
  end

  def star_rating
    average_rating.round.clamp(0, 5)
  end

  def can_be_reviewed_by?(user)
    return false unless user
    return false if account.users.include?(user) # Can't review yourself
    return false if reviews.exists?(reviewer: user) # Already reviewed
    true
  end

  # Favorites methods
  def favorites_count
    favorites.count
  end

  def favorited_by?(user)
    return false unless user
    favorites.exists?(user: user)
  end

  # Trigger search vector update when skills change
  after_save :update_search_vector_if_needed
  after_touch :update_search_vector

  private

  def generate_slug
    if account&.name.present?
      base_slug = account.name.parameterize
    else
      base_slug = title.parameterize if title.present?
    end

    return unless base_slug.present?

    self.slug = base_slug
    ensure_slug_uniqueness
  end

  def ensure_slug_uniqueness
    return unless slug.present?

    original_slug = slug
    counter = 1

    while slug_conflicts?
      self.slug = "#{original_slug}-#{counter}"
      counter += 1
    end
  end

  def slug_conflicts?
    # Check against other marketer profiles
    profile_conflict = self.class.where(slug: slug).where.not(id: id).exists?

    # Check against SEO reserved paths and system routes
    reserved_conflict = slug_reserved?

    # Check against SEO dimension slugs
    seo_conflict = seo_slug_conflict?

    profile_conflict || reserved_conflict || seo_conflict
  end

  def slug_reserved?
    SeoController.reserved_paths.include?(slug)
  end

  def seo_slug_conflict?
    return false unless slug.present?

    # Check if slug conflicts with any SEO dimension
    Skill.exists?(slug: slug) ||
    Location.exists?(slug: slug) ||
    ServiceType.exists?(slug: slug) ||
    Tool.exists?(slug: slug)
  end

  def slug_not_reserved
    if slug_reserved?
      errors.add(:slug, "is reserved and cannot be used")
    end

    if seo_slug_conflict?
      errors.add(:slug, "conflicts with existing skills, locations, service types, or tools")
    end
  end

  def update_search_vector_if_needed
    # The PostgreSQL trigger handles most updates, but we may need to manually
    # trigger updates when skills change (since they're in a separate table)
    touch if saved_changes.key?('title') || saved_changes.key?('bio')
  end

  def update_search_vector
    # Force an update to trigger the PostgreSQL function
    self.class.connection.execute(
      "UPDATE marketer_profiles SET updated_at = NOW() WHERE id = #{id}"
    )
  end
end
