puts '=== Golf n Vibes Admin Setup ==='
admin = Spree::AdminUser.find_or_create_by(email: 'ceo@golfnvibes.com')
admin.first_name = 'Golf n Vibes'
admin.last_name = 'CEO'
admin.password = 'GolfCEO2025!'
admin.password_confirmation = 'GolfCEO2025!'
admin.save!
puts "✅ CEO Admin created: #{admin.email}"
puts 'All admins:'
Spree::AdminUser.all.each { |u| puts "- #{u.email}" }
