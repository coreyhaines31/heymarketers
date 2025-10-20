class JobListing < ApplicationRecord
  belongs_to :company_profile
  belongs_to :location, optional: true

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

  private

  def set_posted_at
    self.posted_at ||= Time.current
  end

  def salary_max_greater_than_min
    return unless salary_min.present? && salary_max.present?

    errors.add(:salary_max, "must be greater than minimum salary") if salary_max <= salary_min
  end
end
