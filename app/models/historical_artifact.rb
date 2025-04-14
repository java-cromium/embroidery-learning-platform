class HistoricalArtifact < ActiveRecord::Base
  belongs_to :historical_period

  validates :name, presence: true
  validates :description, presence: true

  def materials
    metadata['materials'] || []
  end

  def techniques_used
    metadata['techniques'] || []
  end

  def dimensions
    metadata['dimensions']
  end

  def dating_method
    metadata['dating_method']
  end

  def conservation_status
    metadata['conservation_status']
  end
end
