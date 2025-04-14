class EmbroideryTechnique < ActiveRecord::Base
  validates :name, presence: true
  validates :description, presence: true
  validates :difficulty_level, inclusion: { 
    in: ['beginner', 'intermediate', 'advanced'],
    allow_nil: true
  }

  def required_materials
    metadata['required_materials'] || []
  end

  def stitch_types
    metadata['stitch_types'] || []
  end

  def historical_significance
    metadata['historical_significance']
  end

  def common_uses
    metadata['common_uses'] || []
  end

  def variations
    metadata['variations'] || []
  end
end
