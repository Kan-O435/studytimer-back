class RemoveNotNullConstraintFromReviewUserId < ActiveRecord::Migration[7.0] # Railsのバージョンに合わせて[7.0]は適宜変更
  def change
    change_column_null :reviews, :user_id, true
  end
end