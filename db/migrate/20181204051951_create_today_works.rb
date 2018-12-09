class CreateTodayWorks < ActiveRecord::Migration[5.2]
  def change
    create_table :today_works do |t|
      t.float :working_hour, default: 0
      t.datetime :start
      t.datetime :end
      t.date :day
      t.integer :staff_id
      t.timestamps
    end
  end
end
