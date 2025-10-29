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

  def self.sync_now
    JobBoardlySyncJob.perform_now('xml', XML_URL)
  end
end