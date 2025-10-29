class JobSyncLog < ApplicationRecord
  validates :source_type, inclusion: { in: %w[rss xml] }
  validates :source_url, presence: true

  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { order(started_at: :desc) }

  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end

  def total_changes
    jobs_created + jobs_updated + jobs_deleted
  end

  def success_rate
    return 0 if jobs_found == 0
    ((jobs_found - error_messages.length) / jobs_found.to_f * 100).round(2)
  end
end