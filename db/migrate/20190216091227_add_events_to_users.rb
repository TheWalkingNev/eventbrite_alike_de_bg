class AddEventsToUsers < ActiveRecord::Migration[5.2]
  def change
    change_table :attendances do |t|
      t.references :event, index: true
      t.references :user, index: true
    end
  end
end
