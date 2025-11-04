class AddSlugToJobListings < ActiveRecord::Migration[7.1]
  def change
    add_column :job_listings, :slug, :string
    add_index :job_listings, :slug
  end
end
