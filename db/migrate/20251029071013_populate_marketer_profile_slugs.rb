class PopulateMarketerProfileSlugs < ActiveRecord::Migration[7.1]
  def up
    MarketerProfile.where(slug: [nil, '']).find_each do |profile|
      profile.send(:generate_slug)
      profile.save(validate: false) if profile.slug.present?
    end
  end

  def down
    # No need to rollback, slugs can remain
  end
end
