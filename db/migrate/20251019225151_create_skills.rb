class CreateSkills < ActiveRecord::Migration[7.1]
  def change
    create_table :skills do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :skills, :slug, unique: true
  end
end
