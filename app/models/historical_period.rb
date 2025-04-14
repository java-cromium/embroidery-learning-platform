class HistoricalPeriod < ActiveRecord::Base
  has_many :historical_artifacts, dependent: :destroy
  
  validates :name, presence: true
  validates :era, inclusion: { 
    in: ['ancient', 'medieval', 'renaissance', 'modern', 'contemporary'],
    allow_nil: true
  }
  validates :start_year, numericality: { only_integer: true }, allow_nil: true
  validates :end_year, numericality: { only_integer: true }, allow_nil: true
  validate :end_year_after_start_year

  before_save :set_position, if: -> { position.nil? }

  scope :ordered, -> { order(position: :asc) }
  scope :by_era, ->(era) { where(era: era) }
  scope :by_region, ->(region) { where(region: region) }
  scope :chronological, -> { order(start_year: :asc) }

  def year_range
    return nil if start_year.nil? && end_year.nil?
    return "#{start_year} - Present" if end_year.nil?
    return "Until #{end_year}" if start_year.nil?
    "#{start_year} - #{end_year}"
  end

  private

  def end_year_after_start_year
    return if start_year.nil? || end_year.nil?
    if end_year < start_year
      errors.add(:end_year, "must be after start year")
    end
  end

  def set_position
    self.position = (HistoricalPeriod.maximum(:position) || -1) + 1
  end
end
