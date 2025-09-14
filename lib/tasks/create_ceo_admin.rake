namespace :admin do
  desc "Create CEO admin user for Golf n Vibes"
  task create_ceo: :environment do
    puts "🏌️ Creating Golf n Vibes CEO admin user..."
    
    admin = Spree::AdminUser.find_or_initialize_by(email: 'ceo@golfnvibes.com')
    admin.first_name = 'Golf n Vibes'
    admin.last_name = 'CEO'
    admin.password = 'GolfCEO2025!'
    admin.password_confirmation = 'GolfCEO2025!'
    
    if admin.save
      puts "✅ SUCCESS: CEO Admin user created!"
      puts "   Email: #{admin.email}"
      puts "   Name: #{admin.first_name} #{admin.last_name}"
      puts "   You can now login at: /admin_user/sign_in"
    else
      puts "❌ ERROR: Failed to create admin user"
      admin.errors.full_messages.each do |error|
        puts "   - #{error}"
      end
      exit 1
    end
    
    # Display all admin users
    puts "\n👥 All admin users:"
    Spree::AdminUser.all.each do |user|
      puts "   #{user.email} - #{user.first_name} #{user.last_name}"
    end
  end
end