class MarketerSearchService
  DEFAULT_SORT = 'relevance'.freeze
  VALID_SORTS = %w[relevance rate_asc rate_desc recent activity].freeze
  VALID_EXPERIENCE_LEVELS = %w[junior mid senior expert].freeze

  attr_reader :params, :results

  def initialize(params = {})
    @params = params.respond_to?(:with_indifferent_access) ? params.with_indifferent_access : params.to_h.with_indifferent_access
  end

  def search
    @results = base_scope
    apply_filters
    apply_search
    apply_sorting
    paginate_results
    self
  end

  def total_count
    @results&.total_count || 0
  end

  private

  def base_scope
    MarketerProfile.includes(:skills, :location, :account)
  end

  def apply_filters
    # Location filter
    if params[:location_id].present?
      @results = @results.by_location(params[:location_id])
    end

    # Skills filter (multiple skills)
    if params[:skill_ids].present?
      skill_ids = Array(params[:skill_ids]).reject(&:blank?)
      if skill_ids.any?
        @results = @results.joins(:skills).where(skills: { id: skill_ids }).distinct
      end
    end

    # Rate range filter
    if params[:min_rate].present? || params[:max_rate].present?
      @results = @results.by_rate_range(params[:min_rate], params[:max_rate])
    end

    # Availability filter
    if params[:availability].present?
      @results = @results.where(availability: params[:availability])
    end

    # Experience level filter
    if params[:experience_level].present? && VALID_EXPERIENCE_LEVELS.include?(params[:experience_level])
      @results = @results.where(experience_level: params[:experience_level])
    end
  end

  def apply_search
    return unless params[:query].present?

    query = sanitize_search_query(params[:query])

    @results = @results.where(
      "search_vector @@ plainto_tsquery('english', ?)",
      query
    )
  end

  def apply_sorting
    sort_option = params[:sort].presence || DEFAULT_SORT

    case sort_option
    when 'relevance'
      if params[:query].present?
        query = sanitize_search_query(params[:query])
        @results = @results.order(
          "ts_rank(search_vector, plainto_tsquery('english', ?)) DESC",
          query
        )
      else
        @results = @results.order(:id) # Default fallback
      end
    when 'rate_asc'
      @results = @results.order(:hourly_rate)
    when 'rate_desc'
      @results = @results.order(hourly_rate: :desc)
    when 'recent'
      @results = @results.order(created_at: :desc)
    when 'activity'
      @results = @results.order(updated_at: :desc)
    else
      @results = @results.order(:id)
    end
  end

  def paginate_results
    page = [params[:page].to_i, 1].max
    per_page = [params[:per_page].to_i, 12].max
    per_page = [per_page, 50].min # Cap at 50 per page

    @results = @results.page(page).per(per_page)
  end

  def sanitize_search_query(query)
    # Remove special characters that could break PostgreSQL full-text search
    query.gsub(/[^\w\s]/, ' ').strip.squeeze(' ')
  end
end