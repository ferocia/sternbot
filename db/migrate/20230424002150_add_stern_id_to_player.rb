class AddSternIdToPlayer < ActiveRecord::Migration[7.0]
  def change
    add_column :players, :stern_id, :string, null: true
  end
end
