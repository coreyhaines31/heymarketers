class CreateJobSyncLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :job_sync_logs do |t|
      t.string :source_type, null: false      # 'rss', 'xml'
      t.string :source_url, null: false
      t.integer :jobs_found, default: 0
      t.integer :jobs_created, default: 0
      t.integer :jobs_updated, default: 0
      t.integer :jobs_deleted, default: 0
      t.text :error_messages, array: true, default: []
      t.datetime :started_at
      t.datetime :completed_at
      t.boolean :success, default: false

      t.timestamps
    end

    add_index :job_sync_logs, :source_type
    add_index :job_sync_logs, :started_at
    add_index :job_sync_logs, :success
  end
end
