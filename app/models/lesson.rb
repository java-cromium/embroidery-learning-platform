class Lesson < ActiveRecord::Base
  belongs_to :course
  has_many :user_progress, dependent: :destroy
  has_many :users, through: :user_progress

  validates :title, presence: true
  validates :video_url, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :set_position, if: -> { position.nil? }
  before_save :inherit_premium_status, if: :course_id_changed?

  scope :ordered, -> { order(position: :asc) }
  scope :free, -> { where(premium: false) }
  scope :premium, -> { where(premium: true) }

  def progress_for(user)
    user_progress.find_by(user: user)
  end

  def completed_by?(user)
    progress = progress_for(user)
    progress&.completed?
  end

  def accessible_by?(user)
    return true unless premium?
    user&.premium?
  end

  def update_progress(user, percentage)
    progress = user_progress.find_or_initialize_by(user: user)
    progress.progress_percentage = percentage
    progress.completed = (percentage >= 95)
    progress.last_watched_at = Time.current
    progress.save
  end

  private

  def set_position
    self.position = (course.lessons.maximum(:position) || -1) + 1
  end

  def inherit_premium_status
    self.premium = course.premium if course
  end
end
