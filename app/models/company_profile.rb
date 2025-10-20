class CompanyProfile < ApplicationRecord
  belongs_to :account
  belongs_to :location, optional: true

  has_one_attached :logo

  validates :name, presence: true
  validates :description, presence: true

  def slug
    "#{name.parameterize}-#{id}"
  end
end
