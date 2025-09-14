#!/usr/bin/env ruby

puts "=== Golf n Vibes Admin Setup ==="

# Check current admin users
puts "\n1. Checking existing admin users:"
if Spree::AdminUser.any?
  Spree::AdminUser.all.each do |admin|
    puts "   - #{admin.email} (ID: #{admin.id}, Created: #{admin.created_at&.strftime('%Y-%m-%d %H:%M')})"
  end
else
  puts "   No admin users found!"
end

# Check regular users
puts "\n2. Checking regular users:"
if Spree::User.any?
  puts "   Found #{Spree::User.count} regular users"
  Spree::User.limit(3).each do |user|
    puts "   - #{user.email}"
  end
else
  puts "   No regular users found!"
end

# Create CEO admin user
puts "\n3. Creating CEO admin user..."
begin
  admin = Spree::AdminUser.find_or_initialize_by(email: 'ceo@golfnvibes.com')
  admin.first_name = 'Golf n Vibes'
  admin.last_name = 'CEO'
  admin.password = 'GolfCEO2025!'
  admin.password_confirmation = 'GolfCEO2025!'
  
  if admin.save
    puts "   ✅ SUCCESS: CEO Admin created!"
    puts "      Email: #{admin.email}"
    puts "      Name: #{admin.first_name} #{admin.last_name}"
    puts "      ID: #{admin.id}"
  else
    puts "   ❌ FAILED to create CEO admin:"
    admin.errors.full_messages.each do |error|
      puts "      - #{error}"
    end
  end
rescue => e
  puts "   ❌ ERROR: #{e.message}"
end

# Also create a backup admin with standard credentials
puts "\n4. Creating backup admin user..."
begin
  backup_admin = Spree::AdminUser.find_or_initialize_by(email: 'admin@golfnvibes.com')
  backup_admin.first_name = 'Admin'
  backup_admin.last_name = 'User'
  backup_admin.password = 'admin123'
  backup_admin.password_confirmation = 'admin123'
  
  if backup_admin.save
    puts "   ✅ SUCCESS: Backup admin created!"
    puts "      Email: #{backup_admin.email}"
    puts "      Password: admin123"
  else
    puts "   ❌ FAILED to create backup admin:"
    backup_admin.errors.full_messages.each do |error|
      puts "      - #{error}"
    end
  end
rescue => e
  puts "   ❌ ERROR: #{e.message}"
end

# Final summary
puts "\n5. Final admin user list:"
Spree::AdminUser.all.each do |admin|
  puts "   - #{admin.email} (#{admin.first_name} #{admin.last_name})"
end

puts "\n=== Setup Complete ==="
puts "You can now login at /admin_user/sign_in with:"
puts "Primary:  ceo@golfnvibes.com / GolfCEO2025!"
puts "Backup:   admin@golfnvibes.com / admin123"