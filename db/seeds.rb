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

puts "Seed data created successfully!"
puts "#{Skill.count} skills, #{Location.count} locations, #{ServiceType.count} service types"
