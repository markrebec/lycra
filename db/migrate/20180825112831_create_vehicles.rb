class CreateVehicles < ActiveRecord::Migration[5.0]
  def change
    create_table :vehicles do |t|
      t.string :type
      t.string :slug
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
