class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :marketer_profile

  validates :subject, presence: true, length: { minimum: 1, maximum: 200 }
  validates :body, presence: true, length: { minimum: 10, maximum: 5000 }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    update!(read_at: Time.current) unless read?
  end
end
