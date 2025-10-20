class AddSearchFieldsToJobListings < ActiveRecord::Migration[7.1]
  def change
    # Add PostgreSQL full-text search column
    execute <<-SQL
      ALTER TABLE job_listings
      ADD COLUMN search_vector tsvector;
    SQL

    # Add GIN index for fast full-text search
    add_index :job_listings, :search_vector, using: :gin

    # Add indexes for common filter fields
    add_index :job_listings, :employment_type
    add_index :job_listings, :remote_ok
    add_index :job_listings, :posted_at
    add_index :job_listings, [:salary_min, :salary_max]

    # Create trigger to automatically update search_vector
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_job_listings_search_vector() RETURNS trigger AS $$
      DECLARE
        company_name text;
      BEGIN
        -- Get company name
        SELECT company_profiles.name INTO company_name
        FROM company_profiles
        WHERE company_profiles.id = NEW.company_profile_id;

        -- Update search vector with all searchable content
        NEW.search_vector := to_tsvector('english',
          coalesce(NEW.title, '') || ' ' ||
          coalesce(NEW.description, '') || ' ' ||
          coalesce(company_name, '') || ' ' ||
          coalesce(NEW.employment_type, '')
        );

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_job_listings_search_vector_trigger
        BEFORE INSERT OR UPDATE ON job_listings
        FOR EACH ROW EXECUTE FUNCTION update_job_listings_search_vector();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS update_job_listings_search_vector_trigger ON job_listings;"
    execute "DROP FUNCTION IF EXISTS update_job_listings_search_vector();"

    remove_index :job_listings, :search_vector
    remove_index :job_listings, :employment_type
    remove_index :job_listings, :remote_ok
    remove_index :job_listings, :posted_at
    remove_index :job_listings, [:salary_min, :salary_max]

    remove_column :job_listings, :search_vector
  end
end
