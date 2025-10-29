namespace :job_boardly do
  desc "Sync jobs from Job Boardly XML feed"
  task sync: :environment do
    puts "Starting Job Boardly sync..."
    JobBoardlyService.sync_now
    puts "Job Boardly sync completed!"

    # Display sync results
    latest_log = JobSyncLog.order(started_at: :desc).first
    if latest_log
      puts "\nSync Results:"
      puts "Source: #{latest_log.source_type.upcase}"
      puts "Jobs found: #{latest_log.jobs_found}"
      puts "Jobs created: #{latest_log.jobs_created}"
      puts "Jobs updated: #{latest_log.jobs_updated}"
      puts "Jobs deleted: #{latest_log.jobs_deleted}"
      puts "Success: #{latest_log.success? ? 'Yes' : 'No'}"
      puts "Duration: #{latest_log.duration&.round(2)} seconds" if latest_log.duration

      if latest_log.error_messages.any?
        puts "\nErrors:"
        latest_log.error_messages.each { |error| puts "  - #{error}" }
      end
    end
  end

  desc "Show external job statistics"
  task stats: :environment do
    external_jobs = JobListing.external
    native_jobs = JobListing.native

    puts "Job Statistics:"
    puts "External jobs: #{external_jobs.count}"
    puts "Native jobs: #{native_jobs.count}"
    puts "Total jobs: #{JobListing.count}"
    puts "\nExternal job sources:"
    external_jobs.group(:external_source).count.each do |source, count|
      puts "  #{source}: #{count}"
    end
  end
end