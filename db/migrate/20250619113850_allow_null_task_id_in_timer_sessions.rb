class AllowNullTaskIdInTimerSessions < ActiveRecord::Migration[7.1]
  def change
        change_column_null :timer_sessions, :task_id, true
  end
end
