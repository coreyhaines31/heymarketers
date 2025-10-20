class AddCompanySizeToCompanyProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :company_profiles, :company_size, :string

    # Add index for company_size filtering
    add_index :company_profiles, :company_size
  end
end
