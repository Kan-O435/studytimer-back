class Task < ApplicationRecord
  belongs_to :user
  has_many :timer_sessions, dependent: :destroy

  validates :title, presence: true
end
