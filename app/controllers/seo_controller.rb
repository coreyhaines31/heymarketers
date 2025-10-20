class SeoController < ApplicationController
  def skills
    @skill = Skill.find_by!(slug: params[:skill_slug])
    @marketers = MarketerProfile.joins(:skills)
                               .where(skills: { id: @skill.id })
                               .includes(:account, :location, :skills)
                               .page(params[:page])

    @meta_title = "#{@skill.name} Marketers - Find Expert #{@skill.name} Specialists"
    @meta_description = "Hire top #{@skill.name} marketers. Browse verified profiles, rates, and portfolios of #{@skill.name} specialists available for your projects."
  end

  def locations
    @location = Location.find_by!(slug: params[:location_slug])
    @marketers = MarketerProfile.where(location: @location)
                               .includes(:account, :location, :skills)
                               .page(params[:page])

    location_name = @location.name == "Remote" ? "Remote" : @location.name
    @meta_title = "Marketing Specialists in #{location_name} - Local & Remote Experts"
    @meta_description = "Find marketing experts in #{location_name}. Browse profiles of local marketers available for hire with verified skills and experience."
  end

  def skill_location
    @skill = Skill.find_by!(slug: params[:skill_slug])
    @location = Location.find_by!(slug: params[:location_slug])
    @marketers = MarketerProfile.joins(:skills)
                               .where(skills: { id: @skill.id }, location: @location)
                               .includes(:account, :location, :skills)
                               .page(params[:page])

    location_name = @location.name == "Remote" ? "Remote" : @location.name
    @meta_title = "#{@skill.name} Marketers in #{location_name} - Local #{@skill.name} Experts"
    @meta_description = "Find #{@skill.name} specialists in #{location_name}. Browse local marketers with verified #{@skill.name} expertise available for hire."
  end

  private

  def set_meta_tags(title, description)
    @meta_title = title
    @meta_description = description
  end
end
