#!/usr/bin/env ruby

# Simple Golf n Vibes Product Setup - Fixed Version
puts "🏌️ Golf n Vibes - Simple Product Setup"
puts "=" * 50

require_relative 'config/environment'

puts "\n📊 Current Status:"
puts "  Products: #{Spree::Product.count}"
puts "  Stores: #{Spree::Store.count}"

# Ensure we have a default store
default_store = Spree::Store.first
if default_store.nil?
  puts "\n🏪 Creating default store..."
  default_store = Spree::Store.create!(
    name: 'Golf n Vibes',
    url: 'localhost:3000',
    mail_from_address: 'info@golfnvibes.com',
    code: 'golf-n-vibes',
    default: true
  )
end

puts "✅ Store: #{default_store.name}"

# Create shipping category
shipping_category = Spree::ShippingCategory.first || Spree::ShippingCategory.create!(name: 'Default')

# Simple product creation function
def create_simple_product(name, description, price, store, shipping_category)
  puts "  Creating: #{name}"
  
  product = Spree::Product.find_or_create_by!(name: name) do |p|
    p.description = description
    p.price = price
    p.available_on = 1.day.ago
    p.shipping_category = shipping_category
    p.meta_title = "#{name} - Golf n Vibes"
    p.meta_description = description
    p.slug = name.parameterize
  end
  
  # Associate with store
  unless product.stores.include?(store)
    product.stores << store
  end
  
  # Ensure master variant has proper pricing
  master_variant = product.master
  existing_price = master_variant.prices.find_by(currency: 'KES')
  
  if existing_price
    existing_price.update(amount: price)
  else
    master_variant.prices.create!(
      amount: price,
      currency: 'KES'
    )
  end
  
  # Set stock
  stock_location = Spree::StockLocation.first || Spree::StockLocation.create!(
    name: 'Golf n Vibes Warehouse',
    default: true,
    address1: 'Nairobi',
    city: 'Nairobi',
    country: Spree::Country.find_by(iso: 'KE') || Spree::Country.first
  )
  
  stock_item = master_variant.stock_items.find_by(stock_location: stock_location)
  if stock_item
    stock_item.update(count_on_hand: 25)
  else
    stock_item = master_variant.stock_items.create!(
      stock_location: stock_location,
      count_on_hand: 25
    )
  end
  
  product.save!
  product
end

puts "\n📦 Creating Golf n Vibes Products..."

# Golf Products - Simplified List
golf_products = [
  {
    name: "Golf Balls Wallet",
    description: "Premium golf balls themed wallet with stylish design featuring golf ball patterns. Perfect for golf enthusiasts.",
    price: 1850.00
  },
  {
    name: "Putter Covers",
    description: "Stylish putter covers with unique Golf n Vibes designs. Features magnetic closure and premium construction.",
    price: 2000.00
  },
  {
    name: "Dice Blended Cover Set",
    description: "Unique dice-themed golf club covers with blended design patterns. Set includes driver, fairway, and hybrid covers.",
    price: 6000.00
  },
  {
    name: "Animal Covers",
    description: "Fun animal-themed golf covers featuring various animal designs. Perfect for golfers who want to add personality to their game.",
    price: 2500.00
  },
  {
    name: "Fox Cover Set",
    description: "Stylish fox-themed golf club covers with premium design and construction.",
    price: 6200.00
  },
  {
    name: "6 Piecer Little Birdie Full Set",
    description: "Complete set of 6 iron covers (5-PW) from our Little Birdie collection. Each cover features unique birdie-themed designs and premium construction.",
    price: 11800.00
  },
  {
    name: "3 Piecer Birdie Set Covers",
    description: "Premium 3-piece set including driver, fairway wood, and hybrid covers. Features the iconic Golf n Vibes birdie design with superior club protection.",
    price: 6200.00
  },
  {
    name: "5 Piecer Ninja Turtle Head Covers",
    description: "Complete 5-piece set of Ninja Turtle themed head covers. Fun and functional protection for your clubs.",
    price: 9850.00
  },
  {
    name: "7 Piecer Skull Full Set",
    description: "Complete 7-piece skull-themed cover set for the golfer who likes edgy style with premium protection.",
    price: 11350.00
  },
  {
    name: "8 Piecer Full Premium Club Set",
    description: "Ultimate 8-piece premium club cover set with spade design. Complete protection for your entire golf set.",
    price: 15000.00
  },
  {
    name: "Score Cards",
    description: "Premium golf score cards with Golf n Vibes branding and high-quality design.",
    price: 1500.00
  },
  {
    name: "Golf Balls Pouch",
    description: "Stylish golf balls pouch with spade design for carrying extra golf balls on the course.",
    price: 2000.00
  },
  {
    name: "Clove Cover Set",
    description: "Elegant clover-themed golf club covers with lucky charm design.",
    price: 6200.00
  },
  {
    name: "Kitten Cover Set",
    description: "Adorable kitten-themed golf club covers perfect for cat lovers and golf enthusiasts.",
    price: 6200.00
  },
  {
    name: "Ice Cream Full Cover Set",
    description: "Fun ice cream themed full cover set that adds sweetness to your golf game.",
    price: 9950.00
  },
  {
    name: "Golf 4 Piecer Cover Set",
    description: "Professional 4-piece golf cover set with modern design and superior protection.",
    price: 8200.00
  },
  {
    name: "Birdie Cover Set",
    description: "Classic birdie-themed cover set featuring the iconic Golf n Vibes birdie design.",
    price: 6200.00
  },
  {
    name: "Ice Cream Cover Set",
    description: "Delightful ice cream themed cover set with colorful and playful designs.",
    price: 6200.00
  },
  {
    name: "Golf Accessories Pouch",
    description: "Comprehensive golf accessories pouch with multiple compartments for tees, balls, and tools.",
    price: 2850.00
  },
  {
    name: "Golf Towels",
    description: "High-quality golf towels with Golf n Vibes embroidery and superior absorbency.",
    price: 1500.00
  },
  {
    name: "Putter Mallet Cover",
    description: "Specialized mallet putter cover with premium protection and Golf n Vibes styling.",
    price: 2000.00
  },
  {
    name: "Ball Wallet",
    description: "Compact ball wallet for carrying golf balls with additional storage for tees and markers.",
    price: 2500.00
  },
  {
    name: "Golf Cover Set",
    description: "Complete golf cover set with numbered clubs and premium construction.",
    price: 7850.00
  }
]

# Create all products
success_count = 0
golf_products.each do |product_data|
  begin
    create_simple_product(
      product_data[:name],
      product_data[:description],
      product_data[:price],
      default_store,
      shipping_category
    )
    success_count += 1
  rescue => e
    puts "  ❌ Failed to create #{product_data[:name]}: #{e.message}"
  end
end

puts "\n✅ Product Setup Complete!"
puts "📊 Final Status:"
puts "  Total Products: #{Spree::Product.count}"
puts "  Successfully Created: #{success_count}"
puts "  Variants: #{Spree::Variant.count}"
puts "  Stores: #{Spree::Store.count}"

puts "\n🌐 Your Golf n Vibes store is ready!"
puts "  Visit: http://localhost:3000"
puts "  Admin: http://localhost:3001/admin"

