class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :external_id
      t.string :title
      t.datetime :starts_at
      t.text :description
      t.string :image_url

      t.timestamps
    end
    add_index :events, :external_id, unique: true
  end
end
