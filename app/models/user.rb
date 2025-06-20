class User < ApplicationRecord
  include DeviseTokenAuth::Concerns::User
  has_many :tasks, dependent: :destroy
  has_many :timer_sessions, dependent: :destroy
  has_many :reviews, dependent: :destroy

end
