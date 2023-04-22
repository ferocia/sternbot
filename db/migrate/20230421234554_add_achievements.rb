class AddAchievements < ActiveRecord::Migration[7.0]
  def change
    create_table :achievements do |t|
      t.belongs_to :player, null: false
      t.string :slug, null: false
      t.datetime :observed_at, null: false
    end

    add_index :achievements, [:player_id, :slug], unique: true
    add_reference :achievements, :players, foreign_key: true

    add_column :players, :plays, :integer, null: false, default: 0
    add_column :players, :synced_at, :datetime, null: true
  end
end
