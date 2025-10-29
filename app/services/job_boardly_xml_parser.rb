require 'nokogiri'

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
    job_data = {
      external_source: 'jobboardly',
      external_id: job_node.xpath('id').text,
      external_guid: job_node.xpath('guid').text,
      external_url: job_node.xpath('url').text,
      application_url: job_node.xpath('url').text,

      title: job_node.xpath('title').text,
      html_description: job_node.xpath('html_description').text,
      plain_text_description: job_node.xpath('plain_text_description').text,
      description: job_node.xpath('plain_text_description').text.presence || job_node.xpath('html_description').text,

      arrangement: job_node.xpath('arrangement').text,
      location_type: job_node.xpath('location_type').text,
      location_limits: job_node.xpath('location_limits').text,
      employment_type: map_employment_type(job_node.xpath('arrangement').text),

      salary_min: parse_salary(job_node.xpath('salary_minimum').text),
      salary_max: parse_salary(job_node.xpath('salary_maximum').text),
      salary_schedule: job_node.xpath('salary_schedule').text,
      salary_currency: job_node.xpath('salary_currency').text,

      posted_at: parse_datetime(job_node.xpath('published_at').text),
      expires_at: parse_datetime(job_node.xpath('expires_at').text),
      remote_ok: job_node.xpath('location_type').text == 'remote',

      status: 'active'
    }

    # Add company info separately (not part of job listing attributes)
    job_data[:company_name] = job_node.xpath('company_name').text
    job_data[:company_url] = job_node.xpath('company_url').text
    job_data[:company_logo_url] = job_node.xpath('company_logo_url').text

    job_data
  end

  def parse_salary(salary_text)
    return nil if salary_text.blank?

    # Extract numeric value from salary text
    numeric_value = salary_text.gsub(/[^\d.]/, '')
    return nil if numeric_value.blank?

    numeric_value.to_f.to_i
  end

  def parse_datetime(datetime_text)
    return nil if datetime_text.blank?

    Time.parse(datetime_text)
  rescue ArgumentError
    nil
  end

  def map_employment_type(arrangement)
    case arrangement&.downcase
    when 'fulltime', 'full-time', 'full_time'
      'full_time'
    when 'parttime', 'part-time', 'part_time'
      'part_time'
    when 'contract'
      'contract'
    when 'freelance'
      'freelance'
    else
      'contract' # Default fallback
    end
  end
end