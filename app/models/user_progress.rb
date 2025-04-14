class UserProgress < ActiveRecord::Base
  belongs_to :user
  belongs_to :lesson

  validates :user_id, uniqueness: { scope: :lesson_id }
  validates :progress_percentage, numericality: { 
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :watch_time_seconds, numericality: { 
    greater_than_or_equal_to: 0
  }

  before_save :check_completion

  private

  def check_completion
    self.completed = progress_percentage >= 95
  end
end
