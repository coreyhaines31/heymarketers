class CompanyProfile < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true

  has_many :job_listings, dependent: :destroy
  has_one_attached :logo

  validates :name, presence: true
  validates :description, presence: true
  validates :company_size, inclusion: { in: %w[startup small medium large enterprise], allow_blank: true }

  scope :with_active_jobs, -> { joins(:job_listings).where(job_listings: { status: 'active' }).distinct }
  scope :by_company_size, ->(size) { where(company_size: size) if size.present? }

  def slug
    "#{name.parameterize}-#{id}"
  end

  def active_job_count
    job_listings.active.count
  end

  def company_size_display
    company_size&.humanize || 'Not specified'
  end
end
