class Admin::JobSyncController < Admin::BaseController
  def index
    @sync_logs = JobSyncLog.includes(:id)
                          .recent
                          .page(params[:page])
                          .per(20)

    @stats = {
      total_external_jobs: JobListing.external.count,
      total_native_jobs: JobListing.native.count,
      last_sync: JobSyncLog.successful.recent.first&.completed_at,
      failed_syncs_today: JobSyncLog.where(success: false)
                                   .where('started_at >= ?', 1.day.ago)
                                   .count
    }
  end

  def show
    @sync_log = JobSyncLog.find(params[:id])
  end

  def trigger_sync
    JobBoardlyService.sync_from_xml
    redirect_to admin_job_sync_index_path, notice: 'Job sync triggered successfully!'
  end

  private

  def sync_log_params
    params.permit(:page)
  end
end