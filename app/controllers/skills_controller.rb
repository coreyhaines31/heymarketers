class SkillsController < ApplicationController
  def index
    @skills = Skill.ordered
  end
end
