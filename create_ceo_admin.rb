puts "Creating Golf n Vibes CEO admin user..."

admin = Spree::AdminUser.find_or_initialize_by(email: 'ceo@golfnvibes.com')
admin.first_name = 'Golf n Vibes'
admin.last_name = 'CEO'
admin.password = 'GolfCEO2025!'
admin.password_confirmation = 'GolfCEO2025!'

if admin.save!
  puts "SUCCESS: Admin user created - #{admin.email}"
else
  puts "ERROR: Failed to create admin user"
end