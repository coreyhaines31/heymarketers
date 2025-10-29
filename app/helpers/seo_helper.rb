module SeoHelper
  # Generate SEO-friendly URLs for programmatic pages

  def seo_url_for(*dimensions)
    slugs = dimensions.compact.map { |d| d.respond_to?(:slug) ? d.slug : d.to_s }

    case slugs.length
    when 1
      seo_single_path(slug: slugs[0])
    when 2
      seo_double_path(slug1: slugs[0], slug2: slugs[1])
    when 3
      seo_triple_path(slug1: slugs[0], slug2: slugs[1], slug3: slugs[2])
    when 4
      seo_quadruple_path(slug1: slugs[0], slug2: slugs[1], slug3: slugs[2], slug4: slugs[3])
    else
      directory_path
    end
  end

  # Specific helper methods for common combinations
  def skill_url(skill)
    seo_single_path(slug: skill.slug)
  end

  def location_url(location)
    seo_single_path(slug: location.slug)
  end

  def service_type_url(service_type)
    seo_single_path(slug: service_type.slug)
  end

  def tool_url(tool)
    seo_single_path(slug: tool.slug)
  end

  def skill_location_url(skill, location)
    seo_double_path(slug1: skill.slug, slug2: location.slug)
  end

  def skill_service_type_url(skill, service_type)
    seo_double_path(slug1: skill.slug, slug2: service_type.slug)
  end

  def skill_tool_url(skill, tool)
    seo_double_path(slug1: skill.slug, slug2: tool.slug)
  end

  def location_service_type_url(location, service_type)
    seo_double_path(slug1: location.slug, slug2: service_type.slug)
  end

  def location_tool_url(location, tool)
    seo_double_path(slug1: location.slug, slug2: tool.slug)
  end

  def service_type_tool_url(service_type, tool)
    seo_double_path(slug1: service_type.slug, slug2: tool.slug)
  end

  def skill_location_service_type_url(skill, location, service_type)
    seo_triple_path(slug1: skill.slug, slug2: location.slug, slug3: service_type.slug)
  end

  def skill_location_tool_url(skill, location, tool)
    seo_triple_path(slug1: skill.slug, slug2: location.slug, slug3: tool.slug)
  end

  def skill_service_type_tool_url(skill, service_type, tool)
    seo_triple_path(slug1: skill.slug, slug2: service_type.slug, slug3: tool.slug)
  end

  def location_service_type_tool_url(location, service_type, tool)
    seo_triple_path(slug1: location.slug, slug2: service_type.slug, slug3: tool.slug)
  end

  def full_combination_url(skill, location, service_type, tool)
    seo_quadruple_path(slug1: skill.slug, slug2: location.slug, slug3: service_type.slug, slug4: tool.slug)
  end

  # Generate related SEO pages for cross-linking
  def related_seo_pages(current_dimensions = {})
    related = []

    # Add single dimension pages if not already included
    if current_dimensions[:skill].blank?
      Skill.limit(5).each do |skill|
        related << {
          title: "#{skill.name} Specialists",
          url: skill_url(skill),
          type: :skill
        }
      end
    end

    if current_dimensions[:location].blank?
      Location.limit(5).each do |location|
        related << {
          title: "Specialists in #{location.name}",
          url: location_url(location),
          type: :location
        }
      end
    end

    if current_dimensions[:tool].blank?
      Tool.limit(5).each do |tool|
        related << {
          title: "#{tool.name} Experts",
          url: tool_url(tool),
          type: :tool
        }
      end
    end

    # Add combination pages with current dimensions
    if current_dimensions[:skill] && current_dimensions[:location].blank?
      Location.limit(3).each do |location|
        related << {
          title: "#{current_dimensions[:skill].name} Specialists in #{location.name}",
          url: skill_location_url(current_dimensions[:skill], location),
          type: :combination
        }
      end
    end

    if current_dimensions[:location] && current_dimensions[:skill].blank?
      Skill.limit(3).each do |skill|
        related << {
          title: "#{skill.name} Specialists in #{current_dimensions[:location].name}",
          url: skill_location_url(skill, current_dimensions[:location]),
          type: :combination
        }
      end
    end

    related.shuffle.first(8)
  end

  # Generate JSON-LD structured data for SEO
  def seo_structured_data(dimensions, total_count)
    data = {
      "@context": "https://schema.org",
      "@type": "CollectionPage",
      "name": page_title_for_dimensions(dimensions),
      "description": meta_description_for_dimensions(dimensions),
      "url": request.original_url,
      "mainEntity": {
        "@type": "ItemList",
        "numberOfItems": total_count,
        "itemListElement": []
      }
    }

    if dimensions[:skill]
      data[:about] = {
        "@type": "Thing",
        "name": dimensions[:skill].name,
        "description": "Marketing skill specialization"
      }
    end

    if dimensions[:location]
      data[:spatialCoverage] = {
        "@type": "Place",
        "name": dimensions[:location].name
      }
    end

    data.to_json.html_safe
  end

  private

  def page_title_for_dimensions(dimensions)
    parts = []

    parts << dimensions[:skill].name if dimensions[:skill]
    parts << "#{dimensions[:tool].name} Expert" if dimensions[:tool]
    parts << "Specialists"

    if dimensions[:location]
      location_name = dimensions[:location].name == "Remote" ? "Remote" : "in #{dimensions[:location].name}"
      parts << location_name
    end

    parts << "(#{dimensions[:service_type].name})" if dimensions[:service_type]

    "#{parts.join(' ')} - HeyMarketers"
  end

  def meta_description_for_dimensions(dimensions)
    parts = []

    parts << dimensions[:skill].name.downcase if dimensions[:skill]
    parts << dimensions[:tool].name.downcase if dimensions[:tool]

    location_part = ""
    if dimensions[:location]
      location_part = dimensions[:location].name == "Remote" ? "remote" : "in #{dimensions[:location].name.downcase}"
    end
    parts << location_part if location_part.present?

    parts << "for #{dimensions[:service_type].name.downcase} work" if dimensions[:service_type]

    description = "Find expert #{parts.join(' and ')} specialists. Browse verified profiles, rates, and portfolios of marketing professionals available for hire."
    description.truncate(155)
  end
end
