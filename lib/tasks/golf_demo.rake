namespace :golf_demo do
  desc 'Create sample golf tour products for Golf n Vibes theme demonstration'
  task create_products: :environment do
    puts "Creating Golf n Vibes sample products..."
    
    # Create sample golf tour products
    golf_tours = [
      {
        name: "Doha Golf & F1 Experience",
        description: "Experience the thrill of Formula 1 racing combined with championship golf in Qatar. Play on world-class courses while enjoying the excitement of the Qatar Grand Prix.",
        price: 2999.00,
        sku: "GOLF-DOHA-F1"
      },
      {
        name: "Dubai Desert Golf Safari",
        description: "Play golf in the heart of the Dubai desert with stunning views and luxury amenities. Includes helicopter transfers and 5-star accommodation.",
        price: 3499.00,
        sku: "GOLF-DUBAI-SAFARI"
      },
      {
        name: "Scottish Highlands Tour",
        description: "Experience the birthplace of golf with a tour of Scotland's most prestigious courses including St. Andrews and Royal Troon.",
        price: 4299.00,
        sku: "GOLF-SCOTLAND-HIGHLANDS"
      },
      {
        name: "Pebble Beach Masters",
        description: "Play the iconic Pebble Beach Golf Links and other Monterey Peninsula courses in California's stunning coastline.",
        price: 3799.00,
        sku: "GOLF-PEBBLE-BEACH"
      },
      {
        name: "Augusta National Experience",
        description: "Once-in-a-lifetime opportunity to play at Augusta National Golf Club, home of The Masters Tournament.",
        price: 9999.00,
        sku: "GOLF-AUGUSTA-MASTERS"
      },
      {
        name: "New Zealand Golf Adventure",
        description: "Play golf in Middle-earth with New Zealand's most spectacular courses set against breathtaking landscapes.",
        price: 4599.00,
        sku: "GOLF-NEW-ZEALAND"
      }
    ]
    
    golf_tours.each do |tour_data|
      product = Spree::Product.find_or_create_by(sku: tour_data[:sku]) do |p|
        p.name = tour_data[:name]
        p.description = tour_data[:description]
        p.price = tour_data[:price]
        p.available_on = Time.current
        p.shipping_category = Spree::ShippingCategory.first || Spree::ShippingCategory.create!(name: 'Default')
        p.tax_category = Spree::TaxCategory.first || Spree::TaxCategory.create!(name: 'Default')
      end
      
      # Create variant if it doesn't exist
      unless product.master.present?
        product.master = Spree::Variant.create!(
          product: product,
          sku: tour_data[:sku],
          is_master: true,
          price: tour_data[:price],
          cost_price: tour_data[:price] * 0.6,
          track_inventory: false
        )
      end
      
      # Set stock
      stock_location = Spree::StockLocation.first || Spree::StockLocation.create!(
        name: 'Default',
        admin_name: 'Default Location',
        default: true
      )
      
      stock_item = stock_location.stock_items.find_or_create_by(variant: product.master)
      stock_item.update!(count_on_hand: 10, backorderable: true)
      
      puts "✅ Created: #{product.name} - $#{product.price}"
    end
    
    puts "🎉 Successfully created #{golf_tours.count} golf tour products!"
    puts "Visit your homepage at http://localhost:3000 to see them in action."
  end
end
