class JobListing < ApplicationRecord
  EXTERNAL_SOURCES = %w[jobboardly].freeze
  ARRANGEMENTS = %w[fulltime parttime contract freelance].freeze
  LOCATION_TYPES = %w[remote onsite hybrid].freeze

  belongs_to :company_profile
  belongs_to :location, optional: true
  has_many :analytics_events, as: :trackable, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy

  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 50, maximum: 5000 }, unless: :external?
  validates :employment_type, presence: true, inclusion: { in: %w[full_time part_time contract freelance internship] }
  validates :status, inclusion: { in: %w[active inactive expired] }
  validates :salary_min, numericality: { greater_than: 0 }, allow_blank: true
  validates :salary_max, numericality: { greater_than: 0 }, allow_blank: true
  validates :external_source, inclusion: { in: EXTERNAL_SOURCES }, allow_blank: true
  validates :arrangement, inclusion: { in: ARRANGEMENTS }, allow_blank: true
  validates :location_type, inclusion: { in: LOCATION_TYPES }, allow_blank: true
  validates :external_id, uniqueness: { scope: :external_source }, allow_blank: true
  validate :salary_max_greater_than_min

  scope :active, -> { where(status: 'active') }
  scope :recent, -> { order(posted_at: :desc) }
  scope :external, -> { where.not(external_source: nil) }
  scope :native, -> { where(external_source: nil) }
  scope :from_jobboardly, -> { where(external_source: 'jobboardly') }
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
  before_save :generate_slug_if_needed

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

  # Use the slug field from database, or generate one if needed
  def to_param
    slug.presence || super
  end

  # Favorites methods
  def favorites_count
    favorites.count
  end

  def favorited_by?(user)
    return false unless user
    favorites.exists?(user: user)
  end

  # External job methods
  def external?
    external_source.present?
  end

  def native?
    !external?
  end

  def source_display
    external? ? external_source.humanize : 'Native'
  end

  def effective_description
    external? ? (html_description.presence || plain_text_description.presence || description) : description
  end

  def apply_url
    external? ? (application_url.presence || external_url) : nil
  end

  private

  def set_posted_at
    self.posted_at ||= Time.current
  end

  def salary_max_greater_than_min
    return unless salary_min.present? && salary_max.present?

    errors.add(:salary_max, "must be greater than minimum salary") if salary_max <= salary_min
  end

  def generate_slug_if_needed
    return if slug.present? && !title_changed?

    base_slug = title.parameterize
    # Generate a short unique hash (6 characters)
    unique_hash = SecureRandom.hex(3)

    # Combine title slug with unique hash
    new_slug = "#{base_slug}-#{unique_hash}"

    # Ensure uniqueness in case of collision (very unlikely but good practice)
    while JobListing.exists?(slug: new_slug)
      unique_hash = SecureRandom.hex(3)
      new_slug = "#{base_slug}-#{unique_hash}"
    end

    self.slug = new_slug
  end
end
