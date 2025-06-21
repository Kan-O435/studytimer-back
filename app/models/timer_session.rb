class TimerSession < ApplicationRecord
  belongs_to :user
  belongs_to :task, optional: true
  has_one :review,dependent: :destroy

  validates :started_at, presence: true
  validates :duration_minutes, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  validate :ended_at_after_started_at, if: -> { started_at.present? && ended_at.present? }

  private

  def ended_at_after_started_at
    if ended_at < started_at
      errors.add(:ended_at, "must be after started_at")
    end
  end
end
