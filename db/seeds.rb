# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Creating skills..."
skills = [
  "SEO", "Social Media Marketing", "Content Marketing", "Email Marketing",
  "PPC Advertising", "Digital Strategy", "Analytics", "Brand Management",
  "Growth Marketing", "Conversion Optimization", "Influencer Marketing",
  "Video Marketing", "Copywriting", "Marketing Automation"
]

skills.each do |skill_name|
  Skill.find_or_create_by!(name: skill_name)
end

puts "Creating locations..."
locations = [
  "Remote", "United States", "Canada", "United Kingdom", "Australia",
  "New York", "California", "Texas", "Florida", "London", "Toronto",
  "Sydney", "Berlin", "Amsterdam", "San Francisco", "Los Angeles",
  "Chicago", "Boston", "Seattle", "Austin"
]

locations.each do |location_name|
  Location.find_or_create_by!(name: location_name)
end

puts "Creating service types..."
service_types = [
  "Full-time", "Part-time", "Contract", "Freelance", "Project-based",
  "Consulting", "Retainer", "Hourly"
]

service_types.each do |type_name|
  ServiceType.find_or_create_by!(name: type_name)
end

puts "Creating sample users and marketer profiles..."

# Create sample users and accounts with marketer profiles
sample_marketers = [
  {
    email: "sarah.chen@example.com",
    account_name: "Sarah Chen",
    title: "Growth Marketing Specialist",
    bio: "Helped 50+ startups achieve 300% growth through data-driven marketing strategies. Expert in conversion optimization, user acquisition, and retention campaigns.",
    hourly_rate: 85,
    availability: "available",
    experience_level: "mid",
    skills: ["Growth Marketing", "Analytics", "SEO"],
    location: "San Francisco"
  },
  {
    email: "marcus.rodriguez@example.com",
    account_name: "Marcus Rodriguez",
    title: "Performance Marketing Expert",
    bio: "Scaled ad spend from $5K to $500K monthly while maintaining 4x ROAS across multiple channels. Specializing in paid acquisition and marketing automation.",
    hourly_rate: 95,
    availability: "part_time",
    experience_level: "senior",
    skills: ["PPC Advertising", "Marketing Automation", "Analytics"],
    location: "Austin"
  },
  {
    email: "emily.watson@example.com",
    account_name: "Emily Watson",
    title: "Brand Marketing Strategist",
    bio: "Built iconic brand identities for Fortune 500 companies and emerging startups. Expert in brand positioning, creative strategy, and integrated campaigns.",
    hourly_rate: 110,
    availability: "available",
    experience_level: "expert",
    skills: ["Brand Management", "Content Marketing", "Digital Strategy"],
    location: "New York"
  },
  {
    email: "david.kim@example.com",
    account_name: "David Kim",
    title: "Social Media Marketing Manager",
    bio: "Grew social media presence for tech companies from 0 to 100K followers. Specializing in community building and viral content creation.",
    hourly_rate: 75,
    availability: "available",
    experience_level: "mid",
    skills: ["Social Media Marketing", "Content Marketing", "Influencer Marketing"],
    location: "Los Angeles"
  },
  {
    email: "alex.johnson@example.com",
    account_name: "Alex Johnson",
    title: "Junior Marketing Coordinator",
    bio: "Recent marketing graduate with internship experience at top agencies. Passionate about digital marketing and eager to grow expertise in all areas.",
    hourly_rate: 45,
    availability: "available",
    experience_level: "junior",
    skills: ["Digital Strategy", "Content Marketing", "Social Media Marketing"],
    location: "Remote"
  },
  {
    email: "laura.martinez@example.com",
    account_name: "Laura Martinez",
    title: "Email Marketing Strategist",
    bio: "Increased email revenue by 250% for e-commerce brands through advanced segmentation and automation. Expert in lifecycle marketing and retention.",
    hourly_rate: 88,
    availability: "booked",
    experience_level: "senior",
    skills: ["Email Marketing", "Marketing Automation", "Conversion Optimization"],
    location: "Chicago"
  }
]

sample_marketers.each do |marketer_data|
  # Create user
  user = User.find_or_create_by!(email: marketer_data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.confirmed_at = Time.current
  end

  # Create account
  account = Account.find_or_create_by!(name: marketer_data[:account_name])

  # Create membership
  Membership.find_or_create_by!(user: user, account: account) do |m|
    m.role = 'owner'
  end

  # Create marketer profile if it doesn't exist
  unless account.marketer_profile
    location = Location.find_by(name: marketer_data[:location])
    profile = account.create_marketer_profile!(
      title: marketer_data[:title],
      bio: marketer_data[:bio],
      hourly_rate: marketer_data[:hourly_rate],
      availability: marketer_data[:availability],
      experience_level: marketer_data[:experience_level],
      location: location,
      portfolio_url: "https://portfolio.example.com"
    )

    # Add skills
    skills = Skill.where(name: marketer_data[:skills])
    skills.each do |skill|
      MarketerSkill.find_or_create_by!(marketer_profile: profile, skill: skill)
    end
  end
end

# Create sample companies and job listings
puts "Creating sample companies and job listings..."

sample_companies = [
  {
    email: "hiring@techstartup.com",
    company_name: "TechStartup Inc",
    description: "Fast-growing SaaS startup looking to scale our marketing efforts and reach new customers globally.",
    company_size: "startup",
    location: "San Francisco"
  },
  {
    email: "hr@globalcorp.com",
    company_name: "Global Corp",
    description: "Fortune 500 company with a focus on digital transformation and innovative marketing strategies.",
    company_size: "enterprise",
    location: "New York"
  },
  {
    email: "talent@mediumco.com",
    company_name: "MediumCo",
    description: "Growing B2B software company specializing in marketing automation and customer success.",
    company_size: "medium",
    location: "Austin"
  }
]

sample_companies.each do |company_data|
  # Create user
  user = User.find_or_create_by!(email: company_data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.confirmed_at = Time.current
  end

  # Create account
  account = Account.find_or_create_by!(name: company_data[:company_name])

  # Create membership
  Membership.find_or_create_by!(user: user, account: account) do |m|
    m.role = 'owner'
  end

  # Create company profile
  unless account.company_profile
    location = Location.find_by(name: company_data[:location])
    company_profile = account.create_company_profile!(
      name: company_data[:company_name],
      description: company_data[:description],
      company_size: company_data[:company_size],
      location: location,
      website: "https://#{company_data[:company_name].downcase.gsub(' ', '')}.com"
    )

    # Create sample job listings for each company
    case company_data[:company_name]
    when "TechStartup Inc"
      company_profile.job_listings.create!(
        title: "Growth Marketing Manager",
        description: "We're looking for a data-driven growth marketer to help us scale from $1M to $10M ARR. You'll own our entire growth funnel and work directly with the founding team.",
        employment_type: "full_time",
        salary_min: 120000,
        salary_max: 150000,
        remote_ok: true,
        location: location,
        posted_at: 2.days.ago
      )

      company_profile.job_listings.create!(
        title: "Content Marketing Specialist",
        description: "Join our marketing team to create compelling content that drives awareness and engagement. Perfect for someone passionate about storytelling and B2B marketing.",
        employment_type: "full_time",
        salary_min: 80000,
        salary_max: 100000,
        remote_ok: false,
        location: location,
        posted_at: 1.week.ago
      )

    when "Global Corp"
      company_profile.job_listings.create!(
        title: "Senior Digital Marketing Strategist",
        description: "Lead digital marketing initiatives for our global brands. Manage multi-million dollar budgets and work with world-class creative teams.",
        employment_type: "full_time",
        salary_min: 140000,
        salary_max: 180000,
        remote_ok: true,
        location: location,
        posted_at: 3.days.ago
      )

    when "MediumCo"
      company_profile.job_listings.create!(
        title: "Marketing Automation Specialist",
        description: "Help us build and optimize our marketing automation workflows. Work with cutting-edge martech stack and drive measurable results.",
        employment_type: "contract",
        salary_min: 90000,
        salary_max: 120000,
        remote_ok: true,
        location: location,
        posted_at: 5.days.ago
      )
    end
  end
end

puts "Seed data created successfully!"
puts "#{Skill.count} skills, #{Location.count} locations, #{ServiceType.count} service types"
puts "#{User.count} users, #{Account.count} accounts, #{MarketerProfile.count} marketer profiles"
puts "#{CompanyProfile.count} company profiles, #{JobListing.count} job listings"
