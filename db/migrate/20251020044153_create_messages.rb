class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.references :marketer_profile, null: false, foreign_key: true
      t.string :subject
      t.text :body
      t.datetime :read_at

      t.timestamps
    end
  end
end
