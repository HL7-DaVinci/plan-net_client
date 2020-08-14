class CreateZipcodes < ActiveRecord::Migration[5.2]
  def change
    create_table :zipcodes do |t|
    	t.string :zip
    	t.string :city
    	t.string :state
    	t.decimal :latitude, { precision: 10, scale: 6 }
    	t.decimal :longitude, { precision: 10, scale: 6 }
    	t.integer :timezone
    	t.boolean :dst
    	t.string :geopoint
    end
  end
end
