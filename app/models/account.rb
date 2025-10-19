class Account < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  has_one :marketer_profile, dependent: :destroy
  has_one :company_profile, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  def marketer?
    marketer_profile.present?
  end

  def company?
    company_profile.present?
  end

  def owners
    users.joins(:memberships).where(memberships: { role: 'owner' })
  end

  def members
    users.joins(:memberships).where(memberships: { role: 'member' })
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '')

    # Ensure uniqueness
    counter = 1
    original_slug = self.slug
    while Account.exists?(slug: self.slug)
      self.slug = "#{original_slug}-#{counter}"
      counter += 1
    end
  end
end
