class AddFileUploadEnhancements < ActiveRecord::Migration[7.1]
  def change
    # Add file metadata tracking to marketer profiles
    add_column :marketer_profiles, :resume_content_type, :string
    add_column :marketer_profiles, :resume_file_size, :bigint
    add_column :marketer_profiles, :resume_uploaded_at, :datetime
    add_column :marketer_profiles, :profile_photo_processed, :boolean, default: false
    add_column :marketer_profiles, :cover_letter, :text

    # Add portfolio support
    add_column :marketer_profiles, :portfolio_description, :text
    add_column :marketer_profiles, :portfolio_files_count, :integer, default: 0

    # Add file validation flags
    add_column :marketer_profiles, :files_validated, :boolean, default: false
    add_column :marketer_profiles, :validation_errors, :json, default: {}

    # Add indexes for file queries
    add_index :marketer_profiles, :resume_uploaded_at
    add_index :marketer_profiles, :files_validated
    add_index :marketer_profiles, :profile_photo_processed
  end
end
