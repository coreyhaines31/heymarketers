class SeoController < ApplicationController
  before_action :parse_slug_dimensions
  before_action :build_marketer_query
  before_action :set_meta_tags

  def dynamic_page
    @marketers = @query.includes(:account, :location, :skills, :tools)
                       .page(params[:page])
                       .per(20)

    render 'dynamic_page'
  end

  # Route constraint validation methods
  def self.valid_single_slug?(slug)
    return false if reserved_paths.include?(slug)
    skill_exists?(slug) || location_exists?(slug) || service_type_exists?(slug) || tool_exists?(slug)
  end

  def self.valid_double_slugs?(slug1, slug2)
    return false if reserved_paths.include?(slug1) || reserved_paths.include?(slug2)

    # Check all valid two-dimensional combinations
    [
      [skill_exists?(slug1), location_exists?(slug2)],
      [skill_exists?(slug1), service_type_exists?(slug2)],
      [skill_exists?(slug1), tool_exists?(slug2)],
      [location_exists?(slug1), service_type_exists?(slug2)],
      [location_exists?(slug1), tool_exists?(slug2)],
      [service_type_exists?(slug1), tool_exists?(slug2)]
    ].any? { |combo| combo.all? }
  end

  def self.valid_triple_slugs?(slug1, slug2, slug3)
    return false if [slug1, slug2, slug3].any? { |s| reserved_paths.include?(s) }

    # Check all valid three-dimensional combinations
    [
      [skill_exists?(slug1), location_exists?(slug2), service_type_exists?(slug3)],
      [skill_exists?(slug1), location_exists?(slug2), tool_exists?(slug3)],
      [skill_exists?(slug1), service_type_exists?(slug2), tool_exists?(slug3)],
      [location_exists?(slug1), service_type_exists?(slug2), tool_exists?(slug3)]
    ].any? { |combo| combo.all? }
  end

  def self.valid_quadruple_slugs?(slug1, slug2, slug3, slug4)
    return false if [slug1, slug2, slug3, slug4].any? { |s| reserved_paths.include?(s) }

    # All four dimensions: skill, location, service_type, tool
    skill_exists?(slug1) && location_exists?(slug2) &&
    service_type_exists?(slug3) && tool_exists?(slug4)
  end

  private

  def parse_slug_dimensions
    @slugs = params.values_at(:slug, :slug1, :slug2, :slug3, :slug4).compact
    @dimensions = {}

    @slugs.each do |slug|
      if (@skill = Skill.find_by(slug: slug))
        @dimensions[:skill] = @skill
      elsif (@location = Location.find_by(slug: slug))
        @dimensions[:location] = @location
      elsif (@service_type = ServiceType.find_by(slug: slug))
        @dimensions[:service_type] = @service_type
      elsif (@tool = Tool.find_by(slug: slug))
        @dimensions[:tool] = @tool
      end
    end
  end

  def build_marketer_query
    @query = MarketerProfile.all

    if @dimensions[:skill]
      @query = @query.joins(:skills).where(skills: { id: @dimensions[:skill].id })
    end

    if @dimensions[:location]
      @query = @query.where(location: @dimensions[:location])
    end

    if @dimensions[:service_type]
      @query = @query.where(service_type: @dimensions[:service_type])
    end

    if @dimensions[:tool]
      @query = @query.joins(:tools).where(tools: { id: @dimensions[:tool].id })
    end

    @total_count = @query.count
  end

  def set_meta_tags
    title_parts = []
    description_parts = []

    if @dimensions[:skill]
      title_parts << @dimensions[:skill].name
      description_parts << @dimensions[:skill].name.downcase
    end

    if @dimensions[:tool]
      title_parts << "#{@dimensions[:tool].name} Expert"
      description_parts << @dimensions[:tool].name.downcase
    end

    title_parts << "Specialists"

    if @dimensions[:location]
      location_name = @dimensions[:location].name == "Remote" ? "Remote" : "in #{@dimensions[:location].name}"
      title_parts << location_name
      description_parts << location_name.downcase
    end

    if @dimensions[:service_type]
      title_parts << "(#{@dimensions[:service_type].name})"
      description_parts << "for #{@dimensions[:service_type].name.downcase} work"
    end

    @meta_title = "#{title_parts.join(' ')} - HeyMarketers"
    @meta_description = "Find expert #{description_parts.join(' and ')} specialists. Browse verified profiles, rates, and portfolios of marketing professionals available for hire."

    # Ensure meta description isn't too long
    @meta_description = @meta_description.truncate(155) if @meta_description.length > 155
  end

  # Helper methods for route constraints
  def self.skill_exists?(slug)
    Rails.cache.fetch("skill_exists_#{slug}", expires_in: 1.hour) do
      Skill.exists?(slug: slug)
    end
  end

  def self.location_exists?(slug)
    Rails.cache.fetch("location_exists_#{slug}", expires_in: 1.hour) do
      Location.exists?(slug: slug)
    end
  end

  def self.service_type_exists?(slug)
    Rails.cache.fetch("service_type_exists_#{slug}", expires_in: 1.hour) do
      ServiceType.exists?(slug: slug)
    end
  end

  def self.tool_exists?(slug)
    Rails.cache.fetch("tool_exists_#{slug}", expires_in: 1.hour) do
      Tool.exists?(slug: slug)
    end
  end

  def self.reserved_paths
    @reserved_paths ||= %w[
      directory profile jobs dashboard notifications messages reviews
      skills admin api health up new edit create update destroy
      users accounts company_profiles marketer_profiles
    ].freeze
  end
end
