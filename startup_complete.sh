#!/bin/bash
set -e

echo "🏌️ Starting Golf n Vibes Complete Setup..."

cd /rails

# 1. Prepare database
echo "📊 Setting up database..."
./bin/rails db:prepare

# 2. Create admin users
echo "👤 Creating admin users..."
./bin/rails runner "
puts '=== Creating Admin Users ==='

# Create CEO admin
admin = Spree::AdminUser.find_or_create_by(email: 'ceo@golfnvibes.com')
admin.first_name = 'Golf n Vibes'
admin.last_name = 'CEO'
admin.password = 'GolfCEO2025!'
admin.password_confirmation = 'GolfCEO2025!'
if admin.save
  puts '✅ CEO Admin created: ' + admin.email
else
  puts '❌ Failed to create CEO admin'
  admin.errors.full_messages.each { |e| puts e }
end

# Create backup admin  
backup = Spree::AdminUser.find_or_create_by(email: 'admin@golfnvibes.com')
backup.first_name = 'Admin'
backup.last_name = 'User'  
backup.password = 'admin123'
backup.password_confirmation = 'admin123'
if backup.save
  puts '✅ Backup Admin created: ' + backup.email  
else
  puts '❌ Failed to create backup admin'
end

puts 'All admin users:'
Spree::AdminUser.all.each { |u| puts '- ' + u.email }
"

# 3. Load custom Golf n Vibes data
echo "🏌️ Loading Golf n Vibes custom data..."
if [ -f "db/seeds/golf_products.rb" ]; then
  ./bin/rails runner "load 'db/seeds/golf_products.rb'"
  echo "✅ Golf products loaded"
fi

if [ -f "db/seeds/product_categories.rb" ]; then
  ./bin/rails runner "load 'db/seeds/product_categories.rb'"
  echo "✅ Product categories loaded"  
fi

if [ -f "db/seeds/product_options.rb" ]; then
  ./bin/rails runner "load 'db/seeds/product_options.rb'"
  echo "✅ Product options loaded"
fi

echo "🎯 Setup complete! Starting server..."

# 4. Start the Rails server
exec ./bin/rails server -b 0.0.0.0