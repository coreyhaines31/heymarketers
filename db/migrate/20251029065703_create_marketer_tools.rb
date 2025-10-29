class CreateMarketerTools < ActiveRecord::Migration[7.1]
  def change
    create_table :marketer_tools do |t|
      t.references :marketer_profile, null: false, foreign_key: true
      t.references :tool, null: false, foreign_key: true
      t.integer :proficiency_level

      t.timestamps
    end
  end
end
