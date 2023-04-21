class Initial < ActiveRecord::Migration[7.0]
  def change
    create_table :players do |t|
      t.datetime :created_at, null: false
      t.string :tag
      t.string :username
    end

    create_table :high_scores do |t|
      t.belongs_to :player, null: false
      t.integer :value, null: false
      t.datetime :observed_at, null: false
      t.datetime :notified_at, null: true
    end

    add_index :players, :username, unique: true
    # In theory players can share a tag but that would be sad so let's prevent
    # it from happening.
    add_index :players, :tag, unique: true
    add_reference :high_scores, :players, foreign_key: true
  end
end
