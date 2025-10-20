class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true, null: false
      t.string :notification_type, null: false, limit: 50
      t.string :title, null: false, limit: 255
      t.text :message, null: false
      t.datetime :read_at
      t.string :action_url, limit: 500
      t.json :metadata, default: {}
      t.boolean :email_sent, default: false, null: false

      t.timestamps
    end

    # Indexes for efficient querying
    add_index :notifications, :notification_type
    add_index :notifications, [:recipient_id, :read_at]
    add_index :notifications, [:recipient_id, :created_at]
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :created_at
    add_index :notifications, [:recipient_id, :notification_type]

    # Composite index for unread notifications
    add_index :notifications, [:recipient_id], where: "read_at IS NULL", name: "index_notifications_unread"
  end
end
