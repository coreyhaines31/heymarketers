class CreateJobListings < ActiveRecord::Migration[7.1]
  def change
    create_table :job_listings do |t|
      t.references :company_profile, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.references :location, null: true, foreign_key: true
      t.string :employment_type
      t.integer :salary_min
      t.integer :salary_max
      t.boolean :remote_ok, default: false
      t.datetime :posted_at
      t.datetime :expires_at
      t.string :status, default: 'active'

      t.timestamps
    end
  end
end
