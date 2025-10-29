class AddSlugToMarketerProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :marketer_profiles, :slug, :string
    add_index :marketer_profiles, :slug, unique: true
  end
end
