class AddSearchFieldsToMarketerProfiles < ActiveRecord::Migration[7.1]
  def change
    # Add experience level field
    add_column :marketer_profiles, :experience_level, :string

    # Add PostgreSQL full-text search column
    execute <<-SQL
      ALTER TABLE marketer_profiles
      ADD COLUMN search_vector tsvector;
    SQL

    # Add GIN index for fast full-text search
    add_index :marketer_profiles, :search_vector, using: :gin

    # Add indexes for common filter fields
    add_index :marketer_profiles, :availability
    add_index :marketer_profiles, :experience_level
    add_index :marketer_profiles, :hourly_rate

    # Create trigger to automatically update search_vector
    execute <<-SQL
      CREATE OR REPLACE FUNCTION update_marketer_profiles_search_vector() RETURNS trigger AS $$
      DECLARE
        account_name text;
        skills_text text;
      BEGIN
        -- Get account name
        SELECT accounts.name INTO account_name
        FROM accounts
        WHERE accounts.id = NEW.account_id;

        -- Get skills as concatenated text
        SELECT string_agg(skills.name, ' ') INTO skills_text
        FROM skills
        INNER JOIN marketer_skills ON skills.id = marketer_skills.skill_id
        WHERE marketer_skills.marketer_profile_id = NEW.id;

        -- Update search vector with all searchable content
        NEW.search_vector := to_tsvector('english',
          coalesce(account_name, '') || ' ' ||
          coalesce(NEW.title, '') || ' ' ||
          coalesce(NEW.bio, '') || ' ' ||
          coalesce(skills_text, '')
        );

        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_marketer_profiles_search_vector_trigger
        BEFORE INSERT OR UPDATE ON marketer_profiles
        FOR EACH ROW EXECUTE FUNCTION update_marketer_profiles_search_vector();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS update_marketer_profiles_search_vector_trigger ON marketer_profiles;"
    execute "DROP FUNCTION IF EXISTS update_marketer_profiles_search_vector();"

    remove_index :marketer_profiles, :search_vector
    remove_index :marketer_profiles, :availability
    remove_index :marketer_profiles, :experience_level
    remove_index :marketer_profiles, :hourly_rate

    remove_column :marketer_profiles, :search_vector
    remove_column :marketer_profiles, :experience_level
  end
end
