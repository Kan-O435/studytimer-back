class CreateTimerSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :timer_sessions do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :duration_minutes
      t.references :user, null: false, foreign_key: true
      t.references :task, null: true, foreign_key: true

      t.timestamps
    end
  end
end
