# Golf n Vibes Admin User Creation Script
puts "🏌️ Creating Golf n Vibes CEO Admin User..."

# Create or update the CEO admin user
admin_user = Spree::AdminUser.find_or_initialize_by(email: 'ceo@golfnvibes.com')

admin_user.assign_attributes({
  first_name: 'Golf n Vibes',
  last_name: 'CEO',
  password: 'GolfCEO2025!',
  password_confirmation: 'GolfCEO2025!'
})

if admin_user.save
  puts "✅ Admin user created successfully!"
  puts "   Email: #{admin_user.email}"
  puts "   Name: #{admin_user.first_name} #{admin_user.last_name}"
  puts "   Created: #{admin_user.created_at}"
else
  puts "❌ Failed to create admin user:"
  admin_user.errors.full_messages.each do |error|
    puts "   - #{error}"
  end
end

# Show all admin users
puts "\n👥 All Admin Users:"
Spree::AdminUser.all.each do |user|
  puts "   #{user.email} - #{user.first_name} #{user.last_name} (Created: #{user.created_at&.strftime('%Y-%m-%d %H:%M')})"
end

puts "\n🎯 You can now login at:"
puts "   http://#{ENV['HOST'] || 'localhost:3000'}/admin_user/sign_in"
puts "   Email: ceo@golfnvibes.com"
puts "   Password: GolfCEO2025!"