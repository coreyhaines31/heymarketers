class CreateTools < ActiveRecord::Migration[7.1]
  def change
    create_table :tools do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :category

      t.timestamps
    end
    add_index :tools, :slug, unique: true
  end
end
