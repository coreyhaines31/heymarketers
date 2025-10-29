require 'net/http'
require 'uri'

class JobBoardlySyncJob < ApplicationJob
  queue_as :default

  def perform(source_type, source_url)
    sync_log = JobSyncLog.create!(
      source_type: source_type,
      source_url: source_url,
      started_at: Time.current
    )

    begin
      case source_type
      when 'xml'
        sync_from_xml(source_url, sync_log)
      when 'rss'
        sync_from_rss(source_url, sync_log)
      end

      sync_log.update!(
        success: true,
        completed_at: Time.current
      )
    rescue StandardError => e
      sync_log.update!(
        success: false,
        completed_at: Time.current,
        error_messages: [e.message]
      )
      Rails.logger.error "JobBoardly sync failed: #{e.message}"
      raise
    end
  end

  private

  def sync_from_xml(url, sync_log)
    response = fetch_url(url)

    parser = JobBoardlyXmlParser.new(response.body)
    job_data_array = parser.parse

    sync_log.update!(jobs_found: job_data_array.length)

    job_data_array.each do |job_data|
      sync_job(job_data, sync_log)
    end

    # Clean up expired external jobs
    cleanup_expired_jobs(sync_log)
  end

  def sync_from_rss(url, sync_log)
    # RSS parsing implementation - for now, defer to XML
    # Could implement RSS-specific parsing later if needed
    sync_from_xml(url.gsub('rss', 'xml'), sync_log)
  end

  def fetch_url(url)
    uri = URI(url)
    response = Net::HTTP.get_response(uri)

    unless response.code == '200'
      raise "HTTP Error: #{response.code} - #{response.message}"
    end

    response
  end

  def sync_job(job_data, sync_log)
    # Extract company information
    company_info = job_data.extract!(:company_name, :company_url, :company_logo_url)

    # Find existing job by external_id
    existing_job = JobListing.find_by(
      external_source: job_data[:external_source],
      external_id: job_data[:external_id]
    )

    if existing_job
      # Update existing job
      existing_job.update!(job_data.merge(last_synced_at: Time.current))
      sync_log.increment!(:jobs_updated)
    else
      # Create new job with associated company profile
      company_profile = find_or_create_company_profile(company_info)

      JobListing.create!(
        job_data.merge(
          company_profile: company_profile,
          last_synced_at: Time.current
        )
      )
      sync_log.increment!(:jobs_created)
    end
  rescue StandardError => e
    error_message = "Job #{job_data[:external_id]}: #{e.message}"
    sync_log.error_messages = (sync_log.error_messages || []) + [error_message]
    sync_log.save!
    Rails.logger.error error_message
  end

  def find_or_create_company_profile(company_info)
    # Create a generic external company profile
    company_name = company_info[:company_name].presence || 'External Company'

    # Find or create account for external company
    account = Account.find_or_create_by!(name: company_name) do |acc|
      acc.slug = company_name.parameterize
    end

    # Find or create company profile
    account.company_profile || account.create_company_profile!(
      name: company_name,
      description: "External company posting via Job Boardly",
      website: company_info[:company_url],
      location: default_location,
      company_size: 'medium'  # Default to medium for external companies
    )
  end

  def default_location
    @default_location ||= Location.find_or_create_by!(name: 'Remote')
  end

  def cleanup_expired_jobs(sync_log)
    # Mark jobs as expired if they haven't been synced recently (7 days)
    cutoff_time = 7.days.ago
    expired_jobs = JobListing.from_jobboardly
                            .where('last_synced_at < ?', cutoff_time)
                            .where(status: 'active')

    expired_count = expired_jobs.update_all(status: 'expired')
    sync_log.update!(jobs_deleted: expired_count)
  end
end