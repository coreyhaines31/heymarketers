class CreateMarketerSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :marketer_skills do |t|
      t.references :marketer_profile, null: false, foreign_key: true
      t.references :skill, null: false, foreign_key: true

      t.timestamps
    end
  end
end
