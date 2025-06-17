class User < ApplicationRecord
  include DeviseTokenAuth::Concerns::User
end
