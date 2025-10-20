class PortfolioFile < ApplicationRecord
  belongs_to :marketer_profile
  has_one_attached :file

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :file_type, presence: true, length: { maximum: 50 }
  validates :file_size, presence: true, numericality: { greater_than: 0 }
  validates :content_type, presence: true, length: { maximum: 100 }
  validates :display_order, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :url, length: { maximum: 500 }, allow_blank: true

  # File type constants
  FILE_TYPES = [
    'image',      # Screenshots, designs, graphics
    'pdf',        # Case studies, presentations
    'video',      # Demo videos, campaigns
    'document',   # Reports, strategies
    'link',       # External portfolio links
    'code'        # Code samples, repositories
  ].freeze

  validates :file_type, inclusion: { in: FILE_TYPES }

  # Content type validations
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif image/webp].freeze
  ALLOWED_DOCUMENT_TYPES = %w[application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document].freeze
  ALLOWED_VIDEO_TYPES = %w[video/mp4 video/webm video/ogg].freeze

  # File size limits (in bytes)
  MAX_IMAGE_SIZE = 10.megabytes
  MAX_DOCUMENT_SIZE = 25.megabytes
  MAX_VIDEO_SIZE = 100.megabytes

  # Scopes
  scope :ordered, -> { order(:display_order, :created_at) }
  scope :public_files, -> { where(is_public: true) }
  scope :by_type, ->(type) { where(file_type: type) if type.present? }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :set_file_metadata, if: :file_attached?
  after_create :increment_portfolio_count
  after_destroy :decrement_portfolio_count
  before_save :ensure_unique_display_order

  # File processing
  def process_file!
    return unless file.attached?

    case file_type
    when 'image'
      process_image!
    when 'pdf'
      extract_pdf_metadata!
    when 'video'
      extract_video_metadata!
    end

    update!(metadata: metadata.merge(processed: true, processed_at: Time.current))
  end

  # Display helpers
  def file_size_human
    return 'Unknown' unless file_size

    units = %w[B KB MB GB]
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(1)} #{units[unit_index]}"
  end

  def file_type_icon
    case file_type
    when 'image'
      'image'
    when 'pdf'
      'file-text'
    when 'video'
      'video'
    when 'document'
      'file'
    when 'link'
      'external-link'
    when 'code'
      'code'
    else
      'file'
    end
  end

  def file_type_color
    case file_type
    when 'image'
      'green'
    when 'pdf'
      'red'
    when 'video'
      'blue'
    when 'document'
      'gray'
    when 'link'
      'purple'
    when 'code'
      'orange'
    else
      'gray'
    end
  end

  def thumbnail_url
    return nil unless file.attached?

    case file_type
    when 'image'
      Rails.application.routes.url_helpers.rails_representation_url(
        file.variant(resize_to_limit: [300, 200])
      )
    when 'video'
      # For videos, we'd typically generate a thumbnail
      # For now, return a placeholder
      nil
    else
      nil
    end
  end

  def can_preview?
    case file_type
    when 'image', 'pdf'
      true
    when 'video'
      content_type.in?(ALLOWED_VIDEO_TYPES)
    else
      false
    end
  end

  def external_link?
    file_type == 'link' && url.present?
  end

  # Analytics
  def track_view(user = nil)
    AnalyticsEvent.create!(
      user: user,
      trackable: self,
      event_type: 'portfolio_file_view',
      properties: {
        marketer_profile_id: marketer_profile_id,
        file_type: file_type,
        file_size: file_size,
        title: title
      }
    )
  rescue => e
    Rails.logger.error "Failed to track portfolio file view: #{e.message}"
  end

  private

  def file_attached?
    file.attached? || url.present?
  end

  def set_file_metadata
    if file.attached?
      blob = file.blob
      self.file_size = blob.byte_size
      self.content_type = blob.content_type
      self.file_type = determine_file_type(blob.content_type)

      # Validate file size based on type
      validate_file_size
    elsif url.present?
      self.file_type = 'link'
      self.content_type = 'text/html'
      self.file_size = 0
    end
  end

  def determine_file_type(content_type)
    case content_type
    when *ALLOWED_IMAGE_TYPES
      'image'
    when *ALLOWED_DOCUMENT_TYPES
      content_type == 'application/pdf' ? 'pdf' : 'document'
    when *ALLOWED_VIDEO_TYPES
      'video'
    else
      'document'
    end
  end

  def validate_file_size
    max_size = case file_type
               when 'image'
                 MAX_IMAGE_SIZE
               when 'video'
                 MAX_VIDEO_SIZE
               else
                 MAX_DOCUMENT_SIZE
               end

    if file_size > max_size
      errors.add(:file, "is too large. Maximum size for #{file_type} files is #{max_size / 1.megabyte}MB")
    end
  end

  def process_image!
    return unless file.attached? && file_type == 'image'

    # Generate variants for different sizes
    variants = {
      thumbnail: file.variant(resize_to_limit: [150, 150]),
      medium: file.variant(resize_to_limit: [600, 400]),
      large: file.variant(resize_to_limit: [1200, 800])
    }

    metadata[:variants_generated] = true
    metadata[:variants] = variants.keys
  end

  def extract_pdf_metadata!
    return unless file.attached? && file_type == 'pdf'

    # Basic PDF metadata extraction
    metadata[:pages] = 'unknown' # Would implement with PDF processing gem
    metadata[:extractable_text] = true
  end

  def extract_video_metadata!
    return unless file.attached? && file_type == 'video'

    # Basic video metadata
    metadata[:duration] = 'unknown' # Would implement with video processing gem
    metadata[:format] = content_type
  end

  def increment_portfolio_count
    marketer_profile.increment!(:portfolio_files_count)
  end

  def decrement_portfolio_count
    marketer_profile.decrement!(:portfolio_files_count)
  end

  def ensure_unique_display_order
    return unless display_order_changed?

    # Shift existing files to make room for new order
    PortfolioFile.where(marketer_profile: marketer_profile)
                 .where('display_order >= ?', display_order)
                 .where.not(id: id)
                 .update_all('display_order = display_order + 1')
  end
end