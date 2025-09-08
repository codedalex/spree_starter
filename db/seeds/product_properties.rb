# Create Product Properties for Golf Products
puts "🏌️ Creating Product Properties..."

# Define product properties
properties_data = [
  { name: 'material', presentation: 'Material' },
  { name: 'brand', presentation: 'Brand' },
  { name: 'country_of_origin', presentation: 'Country of Origin' },
  { name: 'closure_type', presentation: 'Closure Type' },
  { name: 'club_type', presentation: 'Club Type' },
  { name: 'collection', presentation: 'Collection' },
  { name: 'set_size', presentation: 'Set Size' },
  { name: 'includes', presentation: 'Includes' },
  { name: 'design_theme', presentation: 'Design Theme' },
  { name: 'fit_type', presentation: 'Fit Type' },
  { name: 'interior', presentation: 'Interior' },
  { name: 'features', presentation: 'Features' },
  { name: 'club_numbers', presentation: 'Club Numbers' },
  { name: 'fits', presentation: 'Fits' },
  { name: 'theme', presentation: 'Theme' },
  { name: 'care_instructions', presentation: 'Care Instructions' },
  { name: 'warranty', presentation: 'Warranty' },
  { name: 'dimensions', presentation: 'Dimensions' },
  { name: 'weight', presentation: 'Weight' }
]

# Create properties
properties_data.each do |property_data|
  puts "  Creating property: #{property_data[:presentation]}"
  
  Spree::Property.find_or_create_by!(name: property_data[:name]) do |property|
    property.presentation = property_data[:presentation]
  end
end

puts "✅ Product properties created successfully!"
puts "   Total properties: #{properties_data.length}"
puts "   Properties can be used to add detailed specifications to products"
