class Tool < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :category, presence: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  has_many :marketer_tools, dependent: :destroy
  has_many :marketer_profiles, through: :marketer_tools

  scope :ordered, -> { order(:name) }
  scope :by_category, ->(category) { where(category: category) }

  # Common tool categories
  CATEGORIES = [
    'Analytics & Tracking',
    'Email Marketing',
    'Social Media',
    'SEO Tools',
    'PPC & Advertising',
    'Content Management',
    'Design & Creative',
    'Marketing Automation',
    'CRM & Sales',
    'Project Management'
  ].freeze

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '')

    # Ensure uniqueness
    counter = 1
    original_slug = self.slug
    while Tool.exists?(slug: self.slug)
      self.slug = "#{original_slug}-#{counter}"
      counter += 1
    end
  end
end
