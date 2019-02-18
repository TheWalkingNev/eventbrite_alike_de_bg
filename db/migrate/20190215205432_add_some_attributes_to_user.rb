class AddSomeAttributesToUser < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.text :description
    end
  end
end
