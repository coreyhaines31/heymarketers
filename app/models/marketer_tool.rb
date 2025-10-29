class MarketerTool < ApplicationRecord
  belongs_to :marketer_profile
  belongs_to :tool

  validates :marketer_profile_id, uniqueness: { scope: :tool_id }
  validates :proficiency_level, presence: true, inclusion: { in: 1..5 }

  # Proficiency levels
  PROFICIENCY_LEVELS = {
    1 => 'Beginner',
    2 => 'Basic',
    3 => 'Intermediate',
    4 => 'Advanced',
    5 => 'Expert'
  }.freeze

  scope :by_proficiency, ->(level) { where(proficiency_level: level) }
  scope :expert_level, -> { where(proficiency_level: [4, 5]) }

  def proficiency_name
    PROFICIENCY_LEVELS[proficiency_level]
  end
end
