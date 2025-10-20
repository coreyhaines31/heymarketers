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
    skills: ["Social Media Marketing", "Content Marketing", "Influencer Marketing"],
    location: "Los Angeles"
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

puts "Seed data created successfully!"
puts "#{Skill.count} skills, #{Location.count} locations, #{ServiceType.count} service types"
puts "#{User.count} users, #{Account.count} accounts, #{MarketerProfile.count} marketer profiles"
