# Create Golf Product Categories (Taxons)
puts "🏌️ Creating Golf Product Categories..."

# Create root taxonomy
golf_taxonomy = Spree::Taxonomy.find_or_create_by!(name: 'Golf Products') do |taxonomy|
  taxonomy.position = 1
end

root_taxon = golf_taxonomy.root

# Main Categories
categories = [
  {
    name: 'Golf Club Covers',
    permalink: 'golf-club-covers',
    description: 'Premium golf club head covers for drivers, irons, and putters',
    subcategories: [
      { name: 'Driver Covers', permalink: 'driver-covers', description: 'Protective covers for golf drivers' },
      { name: 'Iron Covers', permalink: 'iron-covers', description: 'Individual iron head covers' },
      { name: 'Putter Covers', permalink: 'putter-covers', description: 'Stylish putter head covers' },
      { name: 'Hybrid Covers', permalink: 'hybrid-covers', description: 'Covers for hybrid golf clubs' }
    ]
  },
  {
    name: 'Golf Sets',
    permalink: 'golf-sets',
    description: 'Complete golf accessory sets and bundles',
    subcategories: [
      { name: '3-Piece Sets', permalink: '3-piece-sets', description: 'Driver, fairway, and hybrid cover sets' },
      { name: '6-Piece Sets', permalink: '6-piece-sets', description: 'Complete iron cover sets' },
      { name: 'Premium Sets', permalink: 'premium-sets', description: 'Luxury golf accessory sets' },
      { name: 'Starter Sets', permalink: 'starter-sets', description: 'Essential golf cover sets for beginners' }
    ]
  },
  {
    name: 'Golf Accessories',
    permalink: 'golf-accessories',
    description: 'Essential golf accessories and equipment',
    subcategories: [
      { name: 'Golf Towels', permalink: 'golf-towels', description: 'Premium golf towels and cleaning accessories' },
      { name: 'Golf Tees', permalink: 'golf-tees', description: 'Wooden and plastic golf tees' },
      { name: 'Ball Markers', permalink: 'ball-markers', description: 'Stylish golf ball markers' },
      { name: 'Golf Gloves', permalink: 'golf-gloves', description: 'Professional golf gloves' }
    ]
  },
  {
    name: 'Golf Wallets & Bags',
    permalink: 'golf-wallets-bags',
    description: 'Golf-themed wallets, bags, and storage solutions',
    subcategories: [
      { name: 'Golf Wallets', permalink: 'golf-wallets', description: 'Leather golf-themed wallets' },
      { name: 'Accessory Bags', permalink: 'accessory-bags', description: 'Small bags for golf accessories' },
      { name: 'Ball Pouches', permalink: 'ball-pouches', description: 'Golf ball storage pouches' },
      { name: 'Golf Pouches', permalink: 'golf-pouches', description: 'Various golf storage pouches' }
    ]
  },
  {
    name: 'Themed Collections',
    permalink: 'themed-collections',
    description: 'Specialty themed golf covers and accessories',
    subcategories: [
      { name: 'Animal Covers', permalink: 'animal-covers', description: 'Fun animal-themed golf covers' },
      { name: 'Novelty Covers', permalink: 'novelty-covers', description: 'Unique and fun golf cover designs' },
      { name: 'Birdie Collection', permalink: 'birdie-collection', description: 'Classic Golf n Vibes birdie themed items' },
      { name: 'Numbered Sets', permalink: 'numbered-sets', description: 'Numbered golf cover sets' }
    ]
  },
  {
    name: 'Set Collections by Size',
    permalink: 'set-collections',
    description: 'Golf sets organized by number of pieces',
    subcategories: [
      { name: '4-Piece Sets', permalink: '4-piece-sets', description: 'Four piece golf cover sets' },
      { name: '5-Piece Sets', permalink: '5-piece-sets', description: 'Five piece golf cover sets' },
      { name: '7-Piece Sets', permalink: '7-piece-sets', description: 'Seven piece golf cover sets' },
      { name: '8-Piece Sets', permalink: '8-piece-sets', description: 'Eight piece golf cover sets' }
    ]
  }
]

# Create categories and subcategories
categories.each do |category_data|
  puts "  Creating category: #{category_data[:name]}"
  
  category = Spree::Taxon.find_or_create_by!(
    name: category_data[:name],
    parent: root_taxon,
    taxonomy: golf_taxonomy
  ) do |taxon|
    taxon.permalink = category_data[:permalink]
    taxon.description = category_data[:description]
    taxon.meta_title = "#{category_data[:name]} - Golf n Vibes"
    taxon.meta_description = category_data[:description]
  end

  # Create subcategories
  if category_data[:subcategories]
    category_data[:subcategories].each do |sub_data|
      puts "    Creating subcategory: #{sub_data[:name]}"
      
      Spree::Taxon.find_or_create_by!(
        name: sub_data[:name],
        parent: category,
        taxonomy: golf_taxonomy
      ) do |taxon|
        taxon.permalink = sub_data[:permalink]
        taxon.description = sub_data[:description]
        taxon.meta_title = "#{sub_data[:name]} - Golf n Vibes"
        taxon.meta_description = sub_data[:description]
      end
    end
  end
end

puts "✅ Golf product categories created successfully!"
puts "   Total categories: #{categories.length}"
puts "   Total subcategories: #{categories.sum { |c| c[:subcategories]&.length || 0 }}"
