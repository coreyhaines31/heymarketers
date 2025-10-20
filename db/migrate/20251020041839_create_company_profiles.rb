class CreateCompanyProfiles < ActiveRecord::Migration[7.1]
  def change
    create_table :company_profiles do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.string :website
      t.boolean :logo_attached
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
