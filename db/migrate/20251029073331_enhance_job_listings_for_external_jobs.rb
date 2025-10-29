class EnhanceJobListingsForExternalJobs < ActiveRecord::Migration[7.1]
  def change
    # Add external job fields
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
  end
end
