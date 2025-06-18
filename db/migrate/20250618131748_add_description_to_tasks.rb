class AddDescriptionToTasks < ActiveRecord::Migration[7.1] # Railsのバージョンによって異なる
  def change
    add_column :tasks, :description, :text
  end
end