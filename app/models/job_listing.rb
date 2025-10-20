class JobListing < ApplicationRecord
  belongs_to :company_profile
  belongs_to :location, optional: true
  has_many :analytics_events, as: :trackable, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 50, maximum: 5000 }
  validates :employment_type, presence: true, inclusion: { in: %w[full_time part_time contract freelance internship] }
  validates :status, inclusion: { in: %w[active inactive expired] }
  validates :salary_min, numericality: { greater_than: 0 }, allow_blank: true
  validates :salary_max, numericality: { greater_than: 0 }, allow_blank: true
  validate :salary_max_greater_than_min

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(posted_at: :desc) }
  scope :by_location, ->(location_id) { where(location_id: location_id) if location_id.present? }
  scope :remote_friendly, -> { where(remote_ok: true) }
  scope :by_employment_type, ->(type) { where(employment_type: type) if type.present? }
  scope :by_salary_range, ->(min_salary, max_salary) do
    scope = all
    if min_salary.present?
      scope = scope.where('salary_min >= ? OR salary_max >= ?', min_salary, min_salary)
    end
    if max_salary.present?
      scope = scope.where('salary_max <= ? OR (salary_min <= ? AND salary_max IS NULL)', max_salary, max_salary)
    end
    scope
  end
  scope :posted_within, ->(timeframe) do
    case timeframe
    when 'day'
      where('posted_at >= ?', 1.day.ago)
    when 'week'
      where('posted_at >= ?', 1.week.ago)
    when 'month'
      where('posted_at >= ?', 1.month.ago)
    else
      all
    end
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

  before_create :set_posted_at

  def display_salary
    return "Competitive" if salary_min.blank? && salary_max.blank?
    return "$#{salary_min.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}+" if salary_max.blank?
    return "Up to $#{salary_max.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}" if salary_min.blank?

    "$#{salary_min.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} - $#{salary_max.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
  end

  def employment_type_display
    employment_type.humanize
  end

  def active?
    status == 'active' && (expires_at.nil? || expires_at > Time.current)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def slug
    "#{title.parameterize}-#{id}"
  end

  # Favorites methods
  def favorites_count
    favorites.count
  end

  def favorited_by?(user)
    return false unless user
    favorites.exists?(user: user)
  end

  private

  def set_posted_at
    self.posted_at ||= Time.current
  end

  def salary_max_greater_than_min
    return unless salary_min.present? && salary_max.present?

    errors.add(:salary_max, "must be greater than minimum salary") if salary_max <= salary_min
  end
end
