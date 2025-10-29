# Job Boardly Integration Plan

## 🎯 Overview

Integrate Job Boardly's RSS and XML feeds to automatically import external job postings while maintaining support for native job postings. This creates a hybrid job board with both curated external jobs and direct employer postings.

## 📊 Feed Analysis

### **RSS Feed**: `https://hey-marketers.jobboardly.com/jobs.rss`
- Standard RSS 2.0 format
- Basic job fields: title, link, description, pubDate, guid
- HTML description in CDATA format

### **XML Feed**: `https://hey-marketers.jobboardly.com/jobs.xml`
- More comprehensive job schema
- Structured fields for better data mapping
- Company information and detailed metadata

**Recommended Approach**: Use XML feed as primary source due to richer data structure.

## 🏗️ Technical Architecture

### **Database Schema Updates**

```ruby
# Enhance existing job_listings table
add_column :job_listings, :external_source, :string
add_column :job_listings, :external_id, :string
add_column :job_listings, :external_url, :string
add_column :job_listings, :external_guid, :string
add_column :job_listings, :arrangement, :string          # parttime, fulltime, contract
add_column :job_listings, :location_type, :string        # remote, onsite, hybrid
add_column :job_listings, :location_limits, :text        # geographic restrictions
add_column :job_listings, :company_logo_url, :string
add_column :job_listings, :application_url, :string
add_column :job_listings, :salary_schedule, :string      # hourly, monthly, yearly
add_column :job_listings, :salary_currency, :string      # USD, EUR, etc.
add_column :job_listings, :html_description, :text
add_column :job_listings, :plain_text_description, :text
add_column :job_listings, :last_synced_at, :datetime

# Add indexes for external job management
add_index :job_listings, [:external_source, :external_id], unique: true
add_index :job_listings, :external_guid
add_index :job_listings, :last_synced_at
add_index :job_listings, :arrangement
add_index :job_listings, :location_type

# Create sync log table
create_table :job_sync_logs do |t|
  t.string :source_type, null: false      # 'rss', 'xml'
  t.string :source_url, null: false
  t.integer :jobs_found, default: 0
  t.integer :jobs_created, default: 0
  t.integer :jobs_updated, default: 0
  t.integer :jobs_deleted, default: 0
  t.text :errors, array: true, default: []
  t.datetime :started_at
  t.datetime :completed_at
  t.boolean :success, default: false
  t.timestamps
end
```

### **Model Enhancements**

```ruby
class JobListing < ApplicationRecord
  EXTERNAL_SOURCES = %w[jobboardly].freeze
  ARRANGEMENTS = %w[fulltime parttime contract freelance].freeze
  LOCATION_TYPES = %w[remote onsite hybrid].freeze

  scope :external, -> { where.not(external_source: nil) }
  scope :native, -> { where(external_source: nil) }
  scope :from_jobboardly, -> { where(external_source: 'jobboardly') }

  def external?
    external_source.present?
  end

  def native?
    !external?
  end

  def source_display
    external? ? external_source.humanize : 'Native'
  end
end

class JobSyncLog < ApplicationRecord
  validates :source_type, inclusion: { in: %w[rss xml] }

  def duration
    return nil unless started_at && completed_at
    completed_at - started_at
  end
end
```

## 🔄 Sync System Implementation

### **Service Classes**

```ruby
class JobBoardlyService
  BASE_URL = 'https://hey-marketers.jobboardly.com'
  RSS_URL = "#{BASE_URL}/jobs.rss"
  XML_URL = "#{BASE_URL}/jobs.xml"

  def self.sync_all
    sync_from_xml
  end

  def self.sync_from_xml
    JobBoardlySyncJob.perform_later('xml', XML_URL)
  end

  def self.sync_from_rss
    JobBoardlySyncJob.perform_later('rss', RSS_URL)
  end
end

class JobBoardlyXmlParser
  def initialize(xml_content)
    @doc = Nokogiri::XML(xml_content)
  end

  def parse
    jobs = []
    @doc.xpath('//job').each do |job_node|
      jobs << extract_job_data(job_node)
    end
    jobs
  end

  private

  def extract_job_data(job_node)
    {
      external_source: 'jobboardly',
      external_id: job_node.xpath('id').text,
      external_guid: job_node.xpath('guid').text,
      external_url: job_node.xpath('url').text,
      application_url: job_node.xpath('url').text,

      title: job_node.xpath('title').text,
      html_description: job_node.xpath('html_description').text,
      plain_text_description: job_node.xpath('plain_text_description').text,

      arrangement: job_node.xpath('arrangement').text,
      location_type: job_node.xpath('location_type').text,
      location_limits: job_node.xpath('location_limits').text,

      company_name: job_node.xpath('company_name').text,
      company_url: job_node.xpath('company_url').text,
      company_logo_url: job_node.xpath('company_logo_url').text,

      salary_min: parse_salary(job_node.xpath('salary_minimum').text),
      salary_max: parse_salary(job_node.xpath('salary_maximum').text),
      salary_schedule: job_node.xpath('salary_schedule').text,
      salary_currency: job_node.xpath('salary_currency').text,

      posted_at: parse_datetime(job_node.xpath('published_at').text),
      expires_at: parse_datetime(job_node.xpath('expires_at').text),

      status: 'active'
    }
  end
end
```

### **Background Jobs**

```ruby
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
        errors: [e.message]
      )
      raise
    end
  end

  private

  def sync_from_xml(url, sync_log)
    response = Net::HTTP.get_response(URI(url))
    raise "HTTP Error: #{response.code}" unless response.code == '200'

    parser = JobBoardlyXmlParser.new(response.body)
    job_data_array = parser.parse

    sync_log.update!(jobs_found: job_data_array.length)

    job_data_array.each do |job_data|
      sync_job(job_data, sync_log)
    end

    # Clean up expired external jobs
    cleanup_expired_jobs(sync_log)
  end

  def sync_job(job_data, sync_log)
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
      company_profile = find_or_create_company_profile(job_data)

      JobListing.create!(
        job_data.merge(
          company_profile: company_profile,
          last_synced_at: Time.current
        )
      )
      sync_log.increment!(:jobs_created)
    end
  rescue StandardError => e
    sync_log.errors << "Job #{job_data[:external_id]}: #{e.message}"
    sync_log.save!
  end

  def find_or_create_company_profile(job_data)
    # Create a generic external company profile
    company_name = job_data[:company_name].presence || 'External Company'

    # Find or create account for external company
    account = Account.find_or_create_by!(name: company_name) do |acc|
      acc.slug = company_name.parameterize
    end

    # Find or create company profile
    account.company_profile || account.create_company_profile!(
      name: company_name,
      description: "External company posting via Job Boardly",
      website: job_data[:company_url],
      location: default_location,
      company_size: 'unknown'
    )
  end
end
```

## 🎨 UI/UX Enhancements

### **Job Listing Indicators**
- Clear badges for "External" vs "Native" jobs
- Job Boardly source attribution
- Direct application links for external jobs
- Company logo display for external companies

### **Admin Interface**
- Sync status dashboard
- Manual sync triggers
- Error monitoring
- Job source analytics

### **User Experience**
- Seamless integration (users see all jobs together)
- Filter by job source (native vs external)
- Clear application flow for external jobs
- Company profile pages for external companies

## 📅 Implementation Timeline

### **Week 1: Foundation**
- Database schema updates
- Basic model enhancements
- XML parser implementation

### **Week 2: Sync System**
- Background job implementation
- Sync service classes
- Error handling and logging

### **Week 3: UI Integration**
- Job listing display updates
- External job indicators
- Application flow enhancements

### **Week 4: Admin & Monitoring**
- Admin dashboard for sync management
- Analytics and reporting
- Testing and refinement

## 🔄 Sync Strategy

### **Frequency**
- Every 30 minutes during business hours
- Every 2 hours during off-hours
- Manual trigger capability

### **Data Management**
- Update existing jobs with latest data
- Mark jobs as expired if not in latest feed
- Maintain sync history for debugging
- Clean up old external jobs (90 days)

## 📊 Success Metrics

- **Job Inventory Growth**: External jobs imported
- **User Engagement**: Views and applications on external jobs
- **Sync Reliability**: Success rate and error monitoring
- **Application Conversion**: External vs native job application rates

## 🛡️ Risk Mitigation

- **Feed Reliability**: Fallback to RSS if XML fails
- **Data Quality**: Validation and sanitization
- **Rate Limiting**: Respectful sync frequency
- **Error Recovery**: Comprehensive logging and retry logic

This integration will significantly expand the job inventory while maintaining a clean user experience and robust data management.