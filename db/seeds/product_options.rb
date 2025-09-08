# Create Product Option Types for Golf Products
puts "🏌️ Creating Product Option Types..."

# Define option types and their values
option_types_data = [
  {
    name: 'color',
    presentation: 'Color',
    values: ['Black', 'Brown', 'Tan', 'White', 'Navy', 'Khaki', 'Forest Green', 'Blue', 'Grey']
  },
  {
    name: 'size',
    presentation: 'Size',
    values: ['Small', 'Medium', 'Large', 'One Size']
  },
  {
    name: 'club-number',
    presentation: 'Club Number',
    values: ['3', '5', '7', '9', 'PW', 'SW', 'LW']
  },
  {
    name: 'set-type',
    presentation: 'Set Type',
    values: ['3-Piece', '6-Piece', '9-Piece', 'Full Set']
  },
  {
    name: 'putter-style',
    presentation: 'Putter Style',
    values: ['Blade', 'Mallet', 'Center Shaft']
  },
  {
    name: 'material',
    presentation: 'Material',
    values: ['Leather', 'Canvas', 'Synthetic Leather', 'Neoprene']
  },
  {
    name: 'design',
    presentation: 'Design',
    values: ['Classic Birdie', 'Premium Birdie', 'Vintage', 'Modern']
  },
  {
    name: 'quantity',
    presentation: 'Quantity',
    values: ['25 Pack', '50 Pack', '100 Pack']
  },
  {
    name: 'length',
    presentation: 'Length',
    values: ['54mm', '70mm', '83mm']
  }
]

# Create option types and values
option_types_data.each do |option_data|
  puts "  Creating option type: #{option_data[:presentation]}"
  
  option_type = Spree::OptionType.find_or_create_by!(name: option_data[:name]) do |ot|
    ot.presentation = option_data[:presentation]
    ot.position = option_types_data.index(option_data) + 1
  end

  # Create option values
  option_data[:values].each do |value|
    Spree::OptionValue.find_or_create_by!(
      name: value.downcase.gsub(/\s+/, '_'),
      option_type: option_type
    ) do |ov|
      ov.presentation = value
      ov.position = option_data[:values].index(value) + 1
    end
  end
end

puts "✅ Product option types created successfully!"
puts "   Total option types: #{option_types_data.length}"
puts "   Total option values: #{option_types_data.sum { |ot| ot[:values].length }}"
