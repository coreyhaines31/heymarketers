class CompanyProfile < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true

  has_many :job_listings, dependent: :destroy
  has_one_attached :logo

  validates :name, presence: true
  validates :description, presence: true

  scope :with_active_jobs, -> { joins(:job_listings).where(job_listings: { status: 'active' }).distinct }

  def slug
    "#{name.parameterize}-#{id}"
  end

  def active_job_count
    job_listings.active.count
  end
end
