class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.integer :rating,null:false
      t.text :comment
      t.references :user, null: false, foreign_key: true
      t.references :timer_session, null: false, foreign_key: true

      t.timestamps
    end
    add_check_constraint :reviews,"rating>=1 AND rating<=5",name:"check_rating_range"
  end
end
