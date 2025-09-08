#!/usr/bin/env ruby

# Complete Golf n Vibes Setup - ensures proper Spree initialization
puts "🏌️ Golf n Vibes - Complete Setup Script"
puts "=" * 50
puts "⏰ Started at: #{Time.now}"

# Enable verbose logging
if ARGV.include?('--trace') || ARGV.include?('--verbose')
  puts "🔍 Verbose mode enabled"
  Rails.logger.level = :debug if defined?(Rails.logger)
end

puts "\n🔧 Loading Rails environment..."
require_relative 'config/environment'
puts "✅ Rails environment loaded"

puts "\n📊 Initial Database Status:"
puts "  Products: #{Spree::Product.count}"
puts "  Stores: #{Spree::Store.count}"

# Step 1: Ensure Spree core is properly seeded
puts "\n🏗️ Step 1: Loading Spree core seeds..."
begin
  Spree::Core::Engine.load_seed
  puts "  ✅ Spree core seeds loaded"
rescue => e
  puts "  ⚠️  Spree core seeds: #{e.message}"
end

# Step 2: Ensure default store exists
puts "\n🏪 Step 2: Ensuring Golf n Vibes store..."
default_store = Spree::Store.first
if default_store.nil?
  puts "  Creating Golf n Vibes store..."
  default_store = Spree::Store.create!(
    name: 'Golf n Vibes',
    url: 'localhost:3000',
    mail_from_address: 'info@golfnvibes.com',
    code: 'golf-n-vibes',
    default: true
  )
  puts "  ✅ Store created: #{default_store.name}"
else
  # Update existing store with Golf n Vibes branding
  default_store.update!(
    name: 'Golf n Vibes',
    url: 'localhost:3000',
    mail_from_address: 'info@golfnvibes.com'
  )
  puts "  ✅ Store updated: #{default_store.name}"
end

# Step 3: Load custom seeds
puts "\n📦 Step 3: Loading custom Golf n Vibes content..."

# Load each seed file individually with error handling
seed_files = [
  'product_categories.rb',
  'product_options.rb', 
  'product_properties.rb',
  'golf_products.rb'
]

seed_files.each do |seed_file|
  seed_path = Rails.root.join('db', 'seeds', seed_file)
  if File.exist?(seed_path)
    puts "  📄 Loading #{seed_file}..."
    puts "     Path: #{seed_path}" if ARGV.include?('--trace')
    
    start_time = Time.now
    begin
      load seed_path
      duration = (Time.now - start_time).round(2)
      puts "  ✅ #{seed_file} loaded successfully (#{duration}s)"
    rescue => e
      puts "  ❌ #{seed_file} failed: #{e.message}"
      puts "     Location: #{e.backtrace.first}"
      if ARGV.include?('--trace')
        puts "     Full backtrace:"
        e.backtrace.first(10).each { |line| puts "       #{line}" }
      end
    end
  else
    puts "  ⚠️  #{seed_file} not found at #{seed_path}, skipping..."
  end
end

puts "\n✅ Complete Setup Finished!"
puts "⏰ Completed at: #{Time.now}"

puts "\n📊 Final Database Status:"
puts "  Products: #{Spree::Product.count}"
puts "  Taxonomies: #{Spree::Taxonomy.count}"
puts "  Taxons: #{Spree::Taxon.count}"
puts "  Variants: #{Spree::Variant.count}"
puts "  Stores: #{Spree::Store.count}"

if ARGV.include?('--trace')
  puts "\n🔍 Detailed Product List:"
  Spree::Product.limit(10).each do |product|
    puts "    - #{product.name} (#{product.price} #{product.currency})"
  end
  puts "    ... and #{Spree::Product.count - 10} more" if Spree::Product.count > 10
end

puts "\n🌐 Your Golf n Vibes store is ready!"
puts "  Backend: http://localhost:3001"
puts "  Admin: http://localhost:3001/admin"
puts "  API: http://localhost:3001/api/v2/storefront"
puts "  Frontend: http://localhost:3000"

puts "\n🚀 Next steps:"
puts "  1. Start the server: RAILS_LOG_LEVEL=debug bin/dev"
puts "  2. Start the frontend: cd ../next-golf && npm run dev"
puts "  3. Visit http://localhost:3000 to see your store!"

puts "\n📝 Log files locations:"
puts "  Rails logs: log/development.log"
puts "  System logs: Use 'tail -f log/development.log' to monitor"
