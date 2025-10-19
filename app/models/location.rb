class Location < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :ordered, -> { order(:name) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '')

    # Ensure uniqueness
    counter = 1
    original_slug = self.slug
    while Location.exists?(slug: self.slug)
      self.slug = "#{original_slug}-#{counter}"
      counter += 1
    end
  end
end
