# Golf n Vibes CEO Demo Setup Script
puts "🏌️ Setting up Golf n Vibes CEO Demo Environment..."

# Create CEO Admin User
puts "👤 Creating CEO admin user..."
admin_user = Spree::AdminUser.find_or_create_by(email: 'ceo@golfnvibes.com') do |user|
  user.first_name = 'Golf n Vibes'
  user.last_name = 'CEO'
  user.password = 'GolfCEO2024!'
  user.password_confirmation = 'GolfCEO2024!'
end

puts "✅ CEO Admin created: #{admin_user.email}"

# Create Test Customer
puts "👥 Creating test customer..."
customer = Spree::User.find_or_create_by(email: 'customer@test.com') do |user|
  user.password = 'TestCustomer123!'
  user.password_confirmation = 'TestCustomer123!'
end

# Add customer address
address = customer.addresses.first || customer.addresses.build
address.update!(
  firstname: 'John',
  lastname: 'Golfer',
  address1: '123 Golf Club Drive',
  city: 'Dubai',
  country: Spree::Country.find_by(name: 'United Arab Emirates') || Spree::Country.first,
  state: Spree::State.first,
  zipcode: '00000',
  phone: '+971-50-123-4567'
)

puts "✅ Test customer created: #{customer.email}"

# Create Golf Tour Products
puts "⛳ Creating premium golf tour products..."

golf_tours = [
  {
    name: "Qatar Grand Prix Golf Experience",
    description: "🏎️🏌️ Experience F1 racing excitement combined with championship golf in Qatar. Play on world-class courses while enjoying VIP access to the Qatar Grand Prix. Includes luxury accommodation, helicopter transfers, and exclusive pit lane access.",
    price: 4999.00,
    sku: "GOLF-QATAR-F1-2024",
    promotion: "Early Bird - Save 20%!"
  },
  {
    name: "Dubai Desert Golf Safari",
    description: "🌅🏌️ Play golf in the heart of the Dubai desert with stunning sunrise views. Features helicopter course-hopping, luxury desert camp accommodation, falconry demonstrations, and camel racing experiences.",
    price: 3799.00,
    sku: "GOLF-DUBAI-SAFARI",
    promotion: "Limited Time Offer"
  },
  {
    name: "Scottish Highlands Masters",
    description: "🏴󠁧󠁢󠁳󠁣󠁴󠁿🏌️ Journey to golf's birthplace with rounds at St. Andrews, Royal Troon, and Carnoustie. Includes whisky tastings, castle visits, and traditional Scottish highland experiences.",
    price: 5299.00,
    sku: "GOLF-SCOTLAND-MASTERS",
    promotion: "Heritage Special"
  },
  {
    name: "Pebble Beach Legends Tour",
    description: "🌊🏌️ Play the iconic Pebble Beach Golf Links and Monterey Peninsula courses. Experience California's stunning coastline with wine tastings, luxury spa treatments, and sunset yacht cruises.",
    price: 4599.00,
    sku: "GOLF-PEBBLE-LEGENDS",
    promotion: "West Coast Elite"
  },
  {
    name: "Augusta National Experience",
    description: "🏆🏌️ Once-in-a-lifetime opportunity to play Augusta National Golf Club, home of The Masters. Includes exclusive clubhouse dining, course photography, and Masters memorabilia collection.",
    price: 14999.00,
    sku: "GOLF-AUGUSTA-MASTERS",
    promotion: "Ultimate Golf Dream"
  },
  {
    name: "New Zealand Golf Adventure",
    description: "🗻🏌️ Play golf in Middle-earth's spectacular landscapes. Features helicopter course access, adventure sports, wine country tours, and Maori cultural experiences in stunning New Zealand.",
    price: 5799.00,
    sku: "GOLF-NEW-ZEALAND",
    promotion: "Adventure Package"
  }
]

golf_tours.each do |tour_data|
  product = Spree::Product.find_or_create_by(sku: tour_data[:sku]) do |p|
    p.name = tour_data[:name]
    p.description = tour_data[:description]
    p.price = tour_data[:price]
    p.available_on = 1.week.ago
    p.shipping_category = Spree::ShippingCategory.find_or_create_by(name: 'Golf Tours')
    p.tax_category = Spree::TaxCategory.find_or_create_by(name: 'Experiences')
    p.meta_title = "#{tour_data[:name]} | Golf n Vibes"
    p.meta_description = tour_data[:description][0..155] + "..."
  end
  
  # Create variants with different package options
  unless product.variants.exists?
    # Standard Package
    standard = product.variants.create!(
      sku: "#{tour_data[:sku]}-STANDARD",
      price: tour_data[:price],
      cost_price: tour_data[:price] * 0.65,
      track_inventory: false,
      is_master: false
    )
    
    # VIP Package (20% more expensive)
    vip = product.variants.create!(
      sku: "#{tour_data[:sku]}-VIP",
      price: tour_data[:price] * 1.2,
      cost_price: tour_data[:price] * 0.65,
      track_inventory: false,
      is_master: false
    )
  end
  
  # Set stock
  stock_location = Spree::StockLocation.find_or_create_by(name: 'Golf Tours HQ') do |sl|
    sl.admin_name = 'Golf n Vibes Headquarters'
    sl.default = true
    sl.address1 = 'Dubai International Golf Club'
    sl.city = 'Dubai'
    sl.country = Spree::Country.find_by(name: 'United Arab Emirates') || Spree::Country.first
  end
  
  product.variants_including_master.each do |variant|
    stock_item = stock_location.stock_items.find_or_create_by(variant: variant)
    stock_item.update!(count_on_hand: 25, backorderable: true)
  end
  
  puts "✅ Created: #{product.name} - $#{product.price} (#{tour_data[:promotion]})"
end

# Create Categories/Taxonomies
puts "📂 Setting up product categories..."
golf_taxonomy = Spree::Taxonomy.find_or_create_by(name: 'Golf Experiences')

destinations = ['Middle East', 'Europe', 'North America', 'Asia Pacific']
destinations.each do |dest|
  taxon = golf_taxonomy.taxons.find_or_create_by(name: dest, parent: golf_taxonomy.root)
  puts "✅ Created category: #{dest}"
end

# Setup Payment Methods for Demo
puts "💳 Configuring demo payment methods..."
Spree::PaymentMethod.find_or_create_by(name: 'Credit Card (Demo)', type: 'Spree::PaymentMethod::CreditCard') do |pm|
  pm.active = true
  pm.display_on = 'both'
  pm.auto_capture = true
  pm.preferences = {
    server: 'test',
    test_mode: true
  }
end

# Create demo shipping methods
puts "🚚 Setting up shipping methods..."
shipping_category = Spree::ShippingCategory.find_or_create_by(name: 'Golf Tours')
zone = Spree::Zone.find_or_create_by(name: 'Worldwide') do |z|
  z.description = 'Global golf tour delivery'
end

Spree::ShippingMethod.find_or_create_by(name: 'Digital Confirmation') do |sm|
  sm.calculator = Spree::Calculator::Shipping::FlatRate.create!(preferences: { amount: 0 })
  sm.shipping_categories = [shipping_category]
  sm.zones = [zone]
end

# Set store preferences
puts "🏪 Configuring store settings..."
store = Spree::Store.default
store.update!(
  name: 'Golf n Vibes',
  url: 'golfnvibes.com',
  seo_title: 'Golf n Vibes - Premium Golf Tour Experiences',
  meta_description: 'Experience luxury golf tours worldwide with Golf n Vibes. Championship courses, VIP access, and unforgettable adventures.',
  meta_keywords: 'golf tours, luxury golf, golf experiences, golf packages, premium golf',
  mail_from_address: 'info@golfnvibes.com',
  customer_support_email: 'support@golfnvibes.com'
)

# Create sample order for demonstration
puts "🛒 Creating sample order for testing..."
order = Spree::Order.create!(
  user: customer,
  store: store,
  currency: 'USD',
  state: 'cart'
)

# Add a product to the order
product = Spree::Product.find_by(sku: 'GOLF-QATAR-F1-2024')
if product
  variant = product.variants_including_master.first
  order.contents.add(variant, 1)
  order.create_proposed_shipments
  puts "✅ Added Qatar F1 Golf Experience to sample cart"
end

puts ""
puts "🎉 Golf n Vibes CEO Demo Environment Setup Complete!"
puts ""
puts "📋 DEMO CREDENTIALS:"
puts "   👨‍💼 CEO Admin Login:"
puts "      Email: ceo@golfnvibes.com"
puts "      Password: GolfCEO2024!"
puts ""
puts "   👤 Test Customer Login:"
puts "      Email: customer@test.com"  
puts "      Password: TestCustomer123!"
puts ""
puts "🌐 DEMO ACCESS:"
puts "   🏪 Storefront: http://your-tunnel-url.com"
puts "   ⚙️ Admin Panel: http://your-tunnel-url.com/admin"
puts "   📱 Next.js App: http://your-nextjs-tunnel-url.com"
puts ""
puts "💡 TESTING SCENARIOS:"
puts "   1. Browse golf tour packages on storefront"
puts "   2. Add Qatar F1 Experience to cart and checkout"  
puts "   3. Login to admin to add/edit products"
puts "   4. Test payment processing (test mode)"
puts "   5. View orders and customer management"
puts "   6. Compare Spree vs Next.js frontend experiences"
puts ""
puts "✅ Ready for CEO demonstration!"
