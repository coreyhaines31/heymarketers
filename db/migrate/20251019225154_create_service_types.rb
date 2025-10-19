class CreateServiceTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :service_types do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :service_types, :slug, unique: true
  end
end
