class Course < ActiveRecord::Base
  has_many :lessons, -> { order(position: :asc) }, dependent: :destroy
  has_many :user_progress, through: :lessons

  validates :title, presence: true
  validates :difficulty_level, inclusion: { in: %w[beginner intermediate advanced] }, allow_nil: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :set_position, if: -> { position.nil? }

  scope :ordered, -> { order(position: :asc) }
  scope :free, -> { where(premium: false) }
  scope :premium, -> { where(premium: true) }

  def completion_percentage(user)
    return 0 unless user
    
    total_lessons = lessons.count
    return 0 if total_lessons.zero?

    completed_lessons = user_progress.where(user: user, completed: true).count
    (completed_lessons.to_f / total_lessons * 100).round(2)
  end

  def accessible_by?(user)
    return true unless premium?
    user&.premium?
  end

  private

  def set_position
    self.position = (Course.maximum(:position) || -1) + 1
  end
end
