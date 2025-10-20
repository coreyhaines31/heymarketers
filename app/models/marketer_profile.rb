class MarketerProfile < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true

  has_many :marketer_skills, dependent: :destroy
  has_many :skills, through: :marketer_skills
  has_many :messages, dependent: :destroy

  has_one_attached :resume
  has_one_attached :profile_photo

  validates :title, presence: true
  validates :bio, presence: true
  validates :hourly_rate, presence: true, numericality: { greater_than: 0 }

  scope :available, -> { where(availability: 'available') }
  scope :by_location, ->(location_id) { where(location_id: location_id) if location_id.present? }
  scope :by_rate_range, ->(min_rate, max_rate) do
    where(hourly_rate: min_rate..max_rate) if min_rate.present? && max_rate.present?
  end

  def display_rate
    "$#{hourly_rate}/hr"
  end

  def slug
    "#{title.parameterize}-#{id}"
  end
end
