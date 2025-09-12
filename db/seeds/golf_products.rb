# Create Golf Products based on Product Lineup Images
puts "🏌️ Creating Golf Products..."

# Helper method to find taxon by permalink
def find_taxon(permalink)
  Spree::Taxon.find_by(permalink: permalink)
end

# Helper method to create product with variants
def create_golf_product(product_data)
  puts "  Creating product: #{product_data[:name]}"
  
  product = nil
  begin
    product = Spree::Product.find_or_create_by!(name: product_data[:name]) do |p|
    p.description = product_data[:description]
    p.price = product_data[:price]
    p.available_on = 1.day.ago
    p.shipping_category = Spree::ShippingCategory.first || Spree::ShippingCategory.create!(name: 'Default')
    p.meta_title = "#{product_data[:name]} - Golf n Vibes"
    p.meta_description = product_data[:description]
    p.slug = product_data[:name].parameterize
  end

  # Add to categories
  if product_data[:categories]
    product_data[:categories].each do |category_permalink|
      taxon = find_taxon(category_permalink)
      if taxon && !product.taxons.include?(taxon)
        product.taxons << taxon
      end
    end
  end

  # Create variants if specified
  if product_data[:variants]
    product_data[:variants].each do |variant_data|
      variant = product.variants.find_or_create_by!(sku: variant_data[:sku]) do |v|
        v.price = variant_data[:price] || product.price
        v.weight = variant_data[:weight] || 0.1
        v.track_inventory = true
        v.stock_items.first&.update(count_on_hand: variant_data[:stock] || 50)
      end

      # Add option values (color, size, etc.)
      if variant_data[:options]
        variant_data[:options].each do |option_name, option_value|
          option_type = Spree::OptionType.find_or_create_by!(name: option_name, presentation: option_name.humanize)
          option_value_obj = option_type.option_values.find_or_create_by!(name: option_value, presentation: option_value)
          
          unless variant.option_values.include?(option_value_obj)
            variant.option_values << option_value_obj
          end
        end
      end
    end
  else
    # Update master variant stock
    master_variant = product.master
    master_variant.stock_items.first&.update(count_on_hand: product_data[:stock] || 25)
  end

  # Add product properties
  if product_data[:properties]
    product_data[:properties].each do |prop_name, prop_value|
      property = Spree::Property.find_or_create_by!(name: prop_name, presentation: prop_name.humanize)
      product.product_properties.find_or_create_by!(property: property) do |pp|
        pp.value = prop_value
      end
    end
  end

    product.save!
    product
  rescue StandardError => e
    puts "    Error creating product #{product_data[:name]}: #{e.message}"
    puts "    This might be due to missing Redis/Sidekiq connection. Continuing..."
    return nil
  end
end

# Golf Products Data based on the product lineup images
golf_products = [
  # Driver Covers
  {
    name: "Premium Leather Driver Cover",
    description: "Handcrafted leather driver head cover with magnetic closure. Features the Golf n Vibes logo and provides excellent protection for your driver.",
    price: 2500.00,
    categories: ['golf-club-covers', 'driver-covers'],
    variants: [
      { sku: 'GNV-DRV-001-BLK', options: { color: 'Black' }, price: 2500.00, stock: 20 },
      { sku: 'GNV-DRV-001-BRN', options: { color: 'Brown' }, price: 2500.00, stock: 15 },
      { sku: 'GNV-DRV-001-TAN', options: { color: 'Tan' }, price: 2500.00, stock: 18 }
    ],
    properties: {
      'Material' => 'Premium Leather',
      'Closure Type' => 'Magnetic',
      'Club Type' => 'Driver',
      'Brand' => 'Golf n Vibes',
      'Country of Origin' => 'Kenya'
    }
  },
  
  {
    name: "Classic Canvas Driver Cover",
    description: "Durable canvas driver cover with vintage Golf n Vibes branding. Perfect for golfers who prefer a classic, understated look.",
    price: 1800.00,
    categories: ['golf-club-covers', 'driver-covers'],
    variants: [
      { sku: 'GNV-DRV-002-KHK', options: { color: 'Khaki' }, price: 1800.00, stock: 25 },
      { sku: 'GNV-DRV-002-NVY', options: { color: 'Navy' }, price: 1800.00, stock: 20 },
      { sku: 'GNV-DRV-002-GRN', options: { color: 'Forest Green' }, price: 1800.00, stock: 22 }
    ],
    properties: {
      'Material' => 'Canvas',
      'Closure Type' => 'Velcro',
      'Club Type' => 'Driver',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Iron Covers Set
  {
    name: "6-Piece Iron Cover Set - Little Birdie Collection",
    description: "Complete set of 6 iron covers (5-PW) from our Little Birdie collection. Each cover features unique birdie-themed designs and premium construction.",
    price: 8500.00,
    categories: ['golf-sets', '6-piece-sets', 'iron-covers'],
    variants: [
      { sku: 'GNV-IRN-SET-001', options: { set_type: '6-Piece' }, price: 8500.00, stock: 15 },
      { sku: 'GNV-IRN-SET-002', options: { set_type: '9-Piece' }, price: 12000.00, stock: 10 }
    ],
    properties: {
      'Set Size' => '6 Pieces (5-PW)',
      'Collection' => 'Little Birdie',
      'Material' => 'Synthetic Leather',
      'Club Numbers' => '5, 6, 7, 8, 9, PW',
      'Brand' => 'Golf n Vibes'
    }
  },

  # 3-Piece Birdie Set
  {
    name: "3-Piece Birdie Set Covers",
    description: "Premium 3-piece set including driver, fairway wood, and hybrid covers. Features the iconic Golf n Vibes birdie design with superior club protection.",
    price: 5500.00,
    categories: ['golf-sets', '3-piece-sets'],
    variants: [
      { sku: 'GNV-3PC-001-STD', options: { design: 'Classic Birdie' }, price: 5500.00, stock: 20 },
      { sku: 'GNV-3PC-001-PRM', options: { design: 'Premium Birdie' }, price: 6500.00, stock: 12 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Includes' => 'Driver, Fairway, Hybrid',
      'Design Theme' => 'Birdie Collection',
      'Material' => 'Premium Synthetic Leather',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Individual Covers
  {
    name: "Fairway Wood Cover",
    description: "Individual fairway wood cover with Golf n Vibes branding. Fits 3-wood and 5-wood clubs perfectly.",
    price: 2200.00,
    categories: ['golf-club-covers'],
    variants: [
      { sku: 'GNV-FWY-001-BLK', options: { color: 'Black', number: '3' }, price: 2200.00, stock: 25 },
      { sku: 'GNV-FWY-002-BLK', options: { color: 'Black', number: '5' }, price: 2200.00, stock: 25 },
      { sku: 'GNV-FWY-001-BRN', options: { color: 'Brown', number: '3' }, price: 2200.00, stock: 15 },
      { sku: 'GNV-FWY-002-BRN', options: { color: 'Brown', number: '5' }, price: 2200.00, stock: 15 }
    ],
    properties: {
      'Club Type' => 'Fairway Wood',
      'Fits' => '3-Wood, 5-Wood',
      'Material' => 'Synthetic Leather',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Hybrid Club Cover",
    description: "Protective hybrid cover designed for modern hybrid clubs. Features stretch-fit design and durable construction.",
    price: 2000.00,
    categories: ['golf-club-covers', 'hybrid-covers'],
    variants: [
      { sku: 'GNV-HYB-001', options: { color: 'Black' }, price: 2000.00, stock: 30 },
      { sku: 'GNV-HYB-002', options: { color: 'Navy' }, price: 2000.00, stock: 25 }
    ],
    properties: {
      'Club Type' => 'Hybrid',
      'Fit Type' => 'Stretch Fit',
      'Material' => 'Neoprene',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Putter Covers
  {
    name: "Premium Putter Cover",
    description: "Elegant putter cover with magnetic closure and soft interior lining. Protects your putter while adding style to your bag.",
    price: 2800.00,
    categories: ['golf-club-covers', 'putter-covers'],
    variants: [
      { sku: 'GNV-PUT-001-BLK', options: { color: 'Black', style: 'Blade' }, price: 2800.00, stock: 20 },
      { sku: 'GNV-PUT-002-BLK', options: { color: 'Black', style: 'Mallet' }, price: 3000.00, stock: 15 },
      { sku: 'GNV-PUT-001-WHT', options: { color: 'White', style: 'Blade' }, price: 2800.00, stock: 18 }
    ],
    properties: {
      'Club Type' => 'Putter',
      'Closure Type' => 'Magnetic',
      'Interior' => 'Soft Fleece Lining',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Golf Accessories
  {
    name: "Golf n Vibes Premium Towel",
    description: "High-quality golf towel with Golf n Vibes embroidery. Features dual-texture weave for optimal cleaning performance.",
    price: 1500.00,
    categories: ['golf-accessories', 'golf-towels'],
    variants: [
      { sku: 'GNV-TWL-001-WHT', options: { color: 'White' }, price: 1500.00, stock: 40 },
      { sku: 'GNV-TWL-001-BLU', options: { color: 'Blue' }, price: 1500.00, stock: 35 },
      { sku: 'GNV-TWL-001-GRY', options: { color: 'Grey' }, price: 1500.00, stock: 30 }
    ],
    properties: {
      'Size' => '40cm x 60cm',
      'Material' => '100% Cotton',
      'Features' => 'Embroidered Logo, Dual Texture',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Wooden Golf Tees Set",
    description: "Pack of 50 premium wooden golf tees. Perfect for everyday play and tournament use.",
    price: 800.00,
    categories: ['golf-accessories', 'golf-tees'],
    variants: [
      { sku: 'GNV-TEE-001-50', options: { quantity: '50 Pack', length: '70mm' }, price: 800.00, stock: 100 },
      { sku: 'GNV-TEE-002-100', options: { quantity: '100 Pack', length: '70mm' }, price: 1400.00, stock: 50 }
    ],
    properties: {
      'Material' => 'Natural Wood',
      'Length' => '70mm',
      'Quantity' => '50 Pieces',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Golf Wallet
  {
    name: "Golf n Vibes Leather Wallet",
    description: "Premium leather wallet with golf-themed design. Features multiple card slots and a coin pocket.",
    price: 3500.00,
    categories: ['golf-wallets-bags', 'golf-wallets'],
    variants: [
      { sku: 'GNV-WAL-001-BLK', options: { color: 'Black' }, price: 3500.00, stock: 25 },
      { sku: 'GNV-WAL-001-BRN', options: { color: 'Brown' }, price: 3500.00, stock: 20 }
    ],
    properties: {
      'Material' => 'Genuine Leather',
      'Features' => '8 Card Slots, Coin Pocket, Bill Compartment',
      'Theme' => 'Golf Design',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Additional Products from Merch Images (IMG-20250827-WA0040.jpg to WA0043.jpg)
  {
    name: "Golf Balls Wallet",
    description: "Premium golf balls themed wallet with stylish design featuring golf ball patterns. Perfect for golf enthusiasts.",
    price: 1850.00,
    categories: ['golf-wallets-bags', 'golf-wallets'],
    variants: [
      { sku: 'GNV-GB-WAL-001', options: { design: 'Classic Golf Balls' }, price: 1850.00, stock: 30 },
      { sku: 'GNV-GB-WAL-002', options: { design: 'Premium Golf Balls' }, price: 2000.00, stock: 25 }
    ],
    properties: {
      'Material' => 'Synthetic Leather',
      'Design' => 'Golf Balls Pattern',
      'Features' => 'Multiple Card Slots, Coin Pocket',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Putter Covers",
    description: "Stylish putter covers with unique Golf n Vibes designs. Features magnetic closure and premium construction.",
    price: 2000.00,
    categories: ['golf-club-covers', 'putter-covers'],
    variants: [
      { sku: 'GNV-PUT-003-CLR', options: { design: 'Colorful Pattern' }, price: 2000.00, stock: 20 },
      { sku: 'GNV-PUT-004-VTG', options: { design: 'Vintage Style' }, price: 2200.00, stock: 18 }
    ],
    properties: {
      'Club Type' => 'Putter',
      'Closure Type' => 'Magnetic',
      'Design' => 'Golf n Vibes Collection',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Dice Blended Cover Set", 
    description: "Unique dice-themed golf club covers with blended design patterns. Set includes driver, fairway, and hybrid covers.",
    price: 6000.00,
    categories: ['golf-sets', '3-piece-sets'],
    variants: [
      { sku: 'GNV-DICE-SET-001', options: { style: 'Standard Dice' }, price: 6000.00, stock: 12 },
      { sku: 'GNV-DICE-SET-002', options: { style: 'Premium Dice' }, price: 7000.00, stock: 8 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Design Theme' => 'Dice Pattern',
      'Includes' => 'Driver, Fairway, Hybrid',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Animal Covers",
    description: "Fun animal-themed golf covers featuring various animal designs. Perfect for golfers who want to add personality to their game.",
    price: 2500.00,
    categories: ['golf-club-covers', 'animal-covers'],
    variants: [
      { sku: 'GNV-ANM-001-ELE', options: { animal: 'Elephant' }, price: 2500.00, stock: 15 },
      { sku: 'GNV-ANM-002-LIN', options: { animal: 'Lion' }, price: 2500.00, stock: 12 },
      { sku: 'GNV-ANM-003-MIX', options: { animal: 'Mixed Set' }, price: 7500.00, stock: 8 }
    ],
    properties: {
      'Design Theme' => 'Animal Collection',
      'Material' => 'Premium Synthetic',
      'Fit' => 'Universal Club Heads',
      'Brand' => 'Golf n Vibes'
    }
  },

  # Additional products based on the app screenshots showing current inventory
  {
    name: "Fox Cover Set",
    description: "Stylish fox-themed golf club covers with premium design and construction.",
    price: 6200.00,
    categories: ['golf-sets', 'animal-covers'],
    variants: [
      { sku: 'GNV-FOX-SET-001', options: { style: 'Classic Fox' }, price: 6200.00, stock: 10 }
    ],
    properties: {
      'Design Theme' => 'Fox Collection',
      'Material' => 'Premium Synthetic',
      'Set Size' => '3 Pieces',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Animal Head Cover",
    description: "Individual animal head covers with detailed craftsmanship and fun designs.",
    price: 2500.00,
    categories: ['golf-club-covers', 'animal-covers'],
    variants: [
      { sku: 'GNV-ANM-HEAD-001', options: { animal: 'Various' }, price: 2500.00, stock: 20 }
    ],
    properties: {
      'Design Theme' => 'Animal Head Collection',
      'Material' => 'Premium Plush',
      'Fit' => 'Universal',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Animal Golf Covers",
    description: "Fun and playful animal-themed golf covers that add personality to your golf bag.",
    price: 2500.00,
    categories: ['golf-club-covers', 'animal-covers'],
    variants: [
      { sku: 'GNV-ANM-CLB-001', options: { type: 'Tiger Pattern' }, price: 2500.00, stock: 15 }
    ],
    properties: {
      'Design Theme' => 'Animal Print Collection',
      'Material' => 'Synthetic Fur',
      'Closure' => 'Velcro',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "5 Piecer Ninja Turtle Head Covers",
    description: "Complete 5-piece set of Ninja Turtle themed head covers. Fun and functional protection for your clubs.",
    price: 9850.00,
    categories: ['golf-sets', '5-piece-sets'],
    variants: [
      { sku: 'GNV-NINJA-SET-001', options: { set_type: '5-Piece Ninja' }, price: 9850.00, stock: 8 }
    ],
    properties: {
      'Set Size' => '5 Pieces',
      'Design Theme' => 'Ninja Turtle Collection',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "7 Piecer Skull Full Set",
    description: "Complete 7-piece skull-themed cover set for the golfer who likes edgy style with premium protection.",
    price: 11350.00,
    categories: ['golf-sets', '7-piece-sets'],
    variants: [
      { sku: 'GNV-SKULL-SET-001', options: { set_type: '7-Piece Skull' }, price: 11350.00, stock: 6 }
    ],
    properties: {
      'Set Size' => '7 Pieces',
      'Design Theme' => 'Skull Collection',
      'Material' => 'Premium Leather',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "8 Piecer Full Premium Club Set",
    description: "Ultimate 8-piece premium club cover set with spade design. Complete protection for your entire golf set.",
    price: 15000.00,
    categories: ['golf-sets', '8-piece-sets'],
    variants: [
      { sku: 'GNV-PREM-SET-001', options: { set_type: '8-Piece Premium' }, price: 15000.00, stock: 4 }
    ],
    properties: {
      'Set Size' => '8 Pieces',
      'Design Theme' => 'Premium Spade Collection',
      'Material' => 'Premium Leather',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Score Cards",
    description: "Premium golf score cards with Golf n Vibes branding and high-quality design.",
    price: 1500.00,
    categories: ['golf-accessories'],
    variants: [
      { sku: 'GNV-SCORE-001', options: { type: 'Standard Pack' }, price: 1500.00, stock: 50 }
    ],
    properties: {
      'Type' => 'Score Cards',
      'Quantity' => '50 Cards',
      'Material' => 'Premium Cardstock',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Golf Balls Pouch",
    description: "Stylish golf balls pouch with spade design for carrying extra golf balls on the course.",
    price: 2000.00,
    categories: ['golf-accessories', 'golf-pouches'],
    variants: [
      { sku: 'GNV-POUCH-001', options: { design: 'Spade Pattern' }, price: 2000.00, stock: 30 }
    ],
    properties: {
      'Design' => 'Spade Collection',
      'Capacity' => '6-8 Golf Balls',
      'Material' => 'Canvas',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Clove cover Set",
    description: "Elegant clover-themed golf club covers with lucky charm design.",
    price: 6200.00,
    categories: ['golf-sets', '3-piece-sets'],
    variants: [
      { sku: 'GNV-CLOVER-SET-001', options: { design: 'Lucky Clover' }, price: 6200.00, stock: 12 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Design Theme' => 'Lucky Clover',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Kitten Cover Set",
    description: "Adorable kitten-themed golf club covers perfect for cat lovers and golf enthusiasts.",
    price: 6200.00,
    categories: ['golf-sets', 'animal-covers'],
    variants: [
      { sku: 'GNV-KITTEN-SET-001', options: { style: 'Black Kitten' }, price: 6200.00, stock: 10 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Design Theme' => 'Kitten Collection',
      'Material' => 'Plush Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Ice Cream Full Cover Set",
    description: "Fun ice cream themed full cover set that adds sweetness to your golf game.",
    price: 9950.00,
    categories: ['golf-sets', 'novelty-covers'],
    variants: [
      { sku: 'GNV-ICE-SET-001', options: { flavor: 'Mixed Flavors' }, price: 9950.00, stock: 8 }
    ],
    properties: {
      'Set Size' => 'Full Set',
      'Design Theme' => 'Ice Cream Collection',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Golf 4 Piecer Cover Set",
    description: "Professional 4-piece golf cover set with modern design and superior protection.",
    price: 8200.00,
    categories: ['golf-sets', '4-piece-sets'],
    variants: [
      { sku: 'GNV-4PC-SET-001', options: { color: 'Black/Gold' }, price: 8200.00, stock: 15 }
    ],
    properties: {
      'Set Size' => '4 Pieces',
      'Design Theme' => 'Professional Collection',
      'Material' => 'Premium Synthetic Leather',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Birdie Cover Set",
    description: "Classic birdie-themed cover set featuring the iconic Golf n Vibes birdie design.",
    price: 6200.00,
    categories: ['golf-sets', 'birdie-collection'],
    variants: [
      { sku: 'GNV-BIRD-SET-001', options: { style: 'Classic Birdie' }, price: 6200.00, stock: 18 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Design Theme' => 'Birdie Collection',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Ice Cream Cover Set",
    description: "Delightful ice cream themed cover set with colorful and playful designs.",
    price: 6200.00,
    categories: ['golf-sets', 'novelty-covers'],
    variants: [
      { sku: 'GNV-ICE-MINI-001', options: { flavor: 'Vanilla/Strawberry' }, price: 6200.00, stock: 12 }
    ],
    properties: {
      'Set Size' => '3 Pieces',
      'Design Theme' => 'Ice Cream Mini Collection',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Clove Full 6 Piecer Set Cover",
    description: "Complete 6-piece clover set for full club protection with lucky charm aesthetic.",
    price: 12500.00,
    categories: ['golf-sets', '6-piece-sets'],
    variants: [
      { sku: 'GNV-CLOVER-6PC-001', options: { design: 'Full Clover Set' }, price: 12500.00, stock: 6 }
    ],
    properties: {
      'Set Size' => '6 Pieces',
      'Design Theme' => 'Lucky Clover Full Set',
      'Material' => 'Premium Synthetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Golf Accessorie Pouch",
    description: "Comprehensive golf accessories pouch with multiple compartments for tees, balls, and tools.",
    price: 2850.00,
    categories: ['golf-accessories', 'golf-pouches'],
    variants: [
      { sku: 'GNV-ACC-POUCH-001', options: { color: 'Brown/Black' }, price: 2850.00, stock: 25 }
    ],
    properties: {
      'Type' => 'Multi-Compartment Pouch',
      'Material' => 'Premium Leather',
      'Features' => 'Tees, Balls, Tools Storage',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Golf Towels",
    description: "High-quality golf towels with Golf n Vibes embroidery and superior absorbency.",
    price: 1500.00,
    categories: ['golf-accessories', 'golf-towels'],
    variants: [
      { sku: 'GNV-TOWEL-002', options: { pattern: 'Golf Themed' }, price: 1500.00, stock: 40 }
    ],
    properties: {
      'Size' => '40cm x 60cm',
      'Material' => '100% Cotton',
      'Design' => 'Golf Themed Pattern',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Putter Mallet Cover",
    description: "Specialized mallet putter cover with premium protection and Golf n Vibes styling.",
    price: 2000.00,
    categories: ['golf-club-covers', 'putter-covers'],
    variants: [
      { sku: 'GNV-MALLET-001', options: { style: 'Skull Design' }, price: 2000.00, stock: 15 }
    ],
    properties: {
      'Club Type' => 'Mallet Putter',
      'Design' => 'Skull Collection',
      'Closure Type' => 'Magnetic',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Ball Wallet",
    description: "Compact ball wallet for carrying golf balls with additional storage for tees and markers.",
    price: 2500.00,
    categories: ['golf-accessories', 'golf-wallets'],
    variants: [
      { sku: 'GNV-BALL-WAL-001', options: { color: 'White/Black' }, price: 2500.00, stock: 20 }
    ],
    properties: {
      'Capacity' => '4 Golf Balls',
      'Material' => 'Synthetic Leather',
      'Features' => 'Tee and Marker Storage',
      'Brand' => 'Golf n Vibes'
    }
  },

  {
    name: "Golf cover Set",
    description: "Complete golf cover set with numbered clubs and premium construction.",
    price: 7850.00,
    categories: ['golf-sets', 'numbered-sets'],
    variants: [
      { sku: 'GNV-GOLF-SET-001', options: { style: '5x3 Configuration' }, price: 7850.00, stock: 10 }
    ],
    properties: {
      'Configuration' => '5x3 Numbered Set',
      'Material' => 'Premium Synthetic',
      'Numbers' => 'Clearly Marked',
      'Brand' => 'Golf n Vibes'
    }
  }
]

# Create all products
golf_products.each do |product_data|
  create_golf_product(product_data)
end

puts "✅ Golf products created successfully!"
puts "   Total products: #{golf_products.length}"
puts "   Products available in admin panel for further customization"
