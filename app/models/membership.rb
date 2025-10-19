class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum role: { owner: 0, member: 1 }

  validates :user_id, uniqueness: { scope: :account_id }
  validates :role, presence: true

  # Ensure each account has at least one owner
  before_destroy :prevent_removing_last_owner

  private

  def prevent_removing_last_owner
    if owner? && account.memberships.where(role: 'owner').count == 1
      errors.add(:base, "Cannot remove the last owner of an account")
      throw :abort
    end
  end
end
