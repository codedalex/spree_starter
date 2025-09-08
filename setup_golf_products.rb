#!/usr/bin/env ruby

# Golf n Vibes Product Setup Script
# This script sets up the complete product catalog for the Golf n Vibes store

puts "🏌️ Golf n Vibes - Product Setup Script"
puts "=" * 50

begin
  # Load Rails environment
  require_relative 'config/environment'
  
  puts "\n📊 Current Database Status:"
  puts "  Products: #{Spree::Product.count}"
  puts "  Taxonomies: #{Spree::Taxonomy.count}"
  puts "  Taxons: #{Spree::Taxon.count}"
  puts "  Stores: #{Spree::Store.count}"
  
  # Ensure default store exists
  puts "\n🏪 Ensuring default store exists..."
  default_store = Spree::Store.first
  if default_store.nil?
    puts "  Creating default Golf n Vibes store..."
    default_store = Spree::Store.create!(
      name: 'Golf n Vibes',
      url: 'localhost:3000',
      mail_from_address: 'info@golfnvibes.com',
      code: 'golf-n-vibes',
      default: true
    )
    puts "  ✅ Default store created: #{default_store.name}"
  else
    puts "  ✅ Default store exists: #{default_store.name}"
  end
  
  puts "\n🏗️ Setting up categories and products..."
  
  # Run the seeds with error handling
  puts "  Loading product categories..."
  begin
    load Rails.root.join('db', 'seeds', 'product_categories.rb')
  rescue => e
    puts "  ⚠️  Product categories: #{e.message}"
  end
  
  puts "  Loading product options..."
  begin
    load Rails.root.join('db', 'seeds', 'product_options.rb')
  rescue => e
    puts "  ⚠️  Product options: #{e.message}"
  end
  
  puts "  Loading product properties..."
  begin
    load Rails.root.join('db', 'seeds', 'product_properties.rb')
  rescue => e
    puts "  ⚠️  Product properties: #{e.message}"
  end
  
  puts "  Loading Golf n Vibes products..."
  load Rails.root.join('db', 'seeds', 'golf_products.rb')
  
  puts "\n✅ Setup Complete!"
  puts "📊 Final Database Status:"
  puts "  Products: #{Spree::Product.count}"
  puts "  Taxonomies: #{Spree::Taxonomy.count}"
  puts "  Taxons: #{Spree::Taxon.count}"
  puts "  Variants: #{Spree::Variant.count}"
  
  puts "\n🌐 API Endpoints Available:"
  puts "  Products: http://localhost:3001/api/v2/storefront/products"
  puts "  Categories: http://localhost:3001/api/v2/storefront/taxons"
  puts "  Admin Panel: http://localhost:3001/admin"
  
  puts "\n🎯 Next Steps:"
  puts "  1. Start the Rails server: rails server -p 3001"
  puts "  2. Start the Next.js frontend: cd ../next-golf && npm run dev"
  puts "  3. Visit http://localhost:3000 to see your Golf n Vibes store!"
  
rescue StandardError => e
  puts "\n❌ Error during setup: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
end
