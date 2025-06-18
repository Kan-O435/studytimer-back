class User < ApplicationRecord
  include DeviseTokenAuth::Concerns::User
  has_many :tasks, dependent: :destroy

end
