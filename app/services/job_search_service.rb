class JobSearchService
  DEFAULT_SORT = 'relevance'.freeze
  VALID_SORTS = %w[relevance date_desc date_asc salary_desc salary_asc].freeze
  VALID_EMPLOYMENT_TYPES = %w[full_time part_time contract freelance internship].freeze
  VALID_COMPANY_SIZES = %w[startup small medium large enterprise].freeze

  attr_reader :params, :results

  def initialize(params = {})
    @params = params.with_indifferent_access
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
    JobListing.active.includes(:company_profile, :location)
  end

  def apply_filters
    # Location filter
    if params[:location_id].present?
      @results = @results.by_location(params[:location_id])
    end

    # Employment type filter (multiple types)
    if params[:employment_types].present?
      employment_types = Array(params[:employment_types]).reject(&:blank?)
      if employment_types.any?
        @results = @results.where(employment_type: employment_types)
      end
    elsif params[:employment_type].present?
      @results = @results.by_employment_type(params[:employment_type])
    end

    # Remote work filter
    if params[:remote_ok] == 'true'
      @results = @results.remote_friendly
    end

    # Salary range filter
    if params[:min_salary].present?
      @results = @results.where('salary_min >= ? OR salary_max >= ?',
                               params[:min_salary].to_i, params[:min_salary].to_i)
    end

    if params[:max_salary].present?
      @results = @results.where('salary_max <= ? OR (salary_min <= ? AND salary_max IS NULL)',
                               params[:max_salary].to_i, params[:max_salary].to_i)
    end

    # Posted date filter
    if params[:posted_within].present?
      date_threshold = case params[:posted_within]
                      when 'day'
                        1.day.ago
                      when 'week'
                        1.week.ago
                      when 'month'
                        1.month.ago
                      else
                        nil
                      end

      if date_threshold
        @results = @results.where('posted_at >= ?', date_threshold)
      end
    end

    # Company size filter
    if params[:company_size].present? && VALID_COMPANY_SIZES.include?(params[:company_size])
      @results = @results.joins(:company_profile)
                         .where(company_profiles: { company_size: params[:company_size] })
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
        @results = @results.order(posted_at: :desc) # Default to recent when no search
      end
    when 'date_desc'
      @results = @results.order(posted_at: :desc)
    when 'date_asc'
      @results = @results.order(posted_at: :asc)
    when 'salary_desc'
      @results = @results.order('COALESCE(salary_max, salary_min, 0) DESC')
    when 'salary_asc'
      @results = @results.order('COALESCE(salary_min, salary_max, 999999) ASC')
    else
      @results = @results.order(posted_at: :desc)
    end
  end

  def paginate_results
    page = [params[:page].to_i, 1].max
    per_page = [params[:per_page].to_i, 15].max
    per_page = [per_page, 50].min # Cap at 50 per page

    @results = @results.page(page).per(per_page)
  end

  def sanitize_search_query(query)
    # Remove special characters that could break PostgreSQL full-text search
    query.gsub(/[^\w\s]/, ' ').strip.squeeze(' ')
  end
end