class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :trackable

  # Relationships will be added here
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships

  def marketer?
    accounts.joins(:marketer_profile).exists?
  end

  def employer?
    accounts.joins(:company_profile).exists?
  end

  def full_name
    # Will add first_name and last_name fields later
    email.split('@').first.titleize
  end
end
