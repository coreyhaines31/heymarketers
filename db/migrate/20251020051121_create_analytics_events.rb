class CreateAnalyticsEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :analytics_events do |t|
      t.references :user, null: true, foreign_key: true # Allow anonymous tracking
      t.references :trackable, polymorphic: true, null: false
      t.string :event_type, null: false, limit: 50
      t.json :properties, default: {}
      t.string :ip_address, limit: 45 # IPv6 support
      t.text :user_agent
      t.string :session_id, limit: 128
      t.string :referrer, limit: 500
      t.string :utm_source, limit: 100
      t.string :utm_medium, limit: 100
      t.string :utm_campaign, limit: 100

      t.timestamps
    end

    # Indexes for efficient analytics queries
    add_index :analytics_events, :event_type
    add_index :analytics_events, [:trackable_type, :trackable_id]
    add_index :analytics_events, [:user_id, :event_type]
    add_index :analytics_events, [:user_id, :created_at]
    add_index :analytics_events, :created_at
    add_index :analytics_events, :session_id
    add_index :analytics_events, [:event_type, :created_at]

    # Composite indexes for common queries
    add_index :analytics_events, [:trackable_type, :trackable_id, :event_type], name: "index_analytics_trackable_event"
    add_index :analytics_events, [:created_at, :event_type, :trackable_type], name: "index_analytics_time_event_type"
  end
end
