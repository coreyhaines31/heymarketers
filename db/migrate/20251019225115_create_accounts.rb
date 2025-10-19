class CreateAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :accounts, :slug, unique: true
  end
end
