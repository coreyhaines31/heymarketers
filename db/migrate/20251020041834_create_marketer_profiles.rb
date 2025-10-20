class CreateMarketerProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :marketer_profiles do |t|
      t.references :account, null: false, foreign_key: true
      t.string :title
      t.text :bio
      t.integer :hourly_rate
      t.references :location, null: false, foreign_key: true
      t.string :availability
      t.string :portfolio_url
      t.boolean :resume_attached

      t.timestamps
    end
  end
end
