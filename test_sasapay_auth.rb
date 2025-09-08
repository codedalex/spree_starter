# SasaPay Authentication Test Script
puts "🔐 SasaPay Authentication Test"
puts "=" * 50

# Get the SasaPay payment method
sasapay_method = Spree::PaymentMethod::Sasapay.active.first

if sasapay_method.nil?
  puts "❌ No active SasaPay payment method found!"
  puts "   Please run: rails runner db/seeds/sasapay_payment_method.rb"
  exit 1
end

puts "\n📋 SasaPay Configuration:"
puts "  Name: #{sasapay_method.name}"
puts "  Environment: #{sasapay_method.preferred_environment}"
puts "  Client ID: #{sasapay_method.preferred_client_id || 'NOT SET'}"
puts "  Client Secret: #{sasapay_method.preferred_client_secret ? '[SET]' : 'NOT SET'}"
puts "  Merchant Code: #{sasapay_method.preferred_merchant_code || 'NOT SET'}"
puts "  Callback URL: #{sasapay_method.preferred_callback_url || 'NOT SET'}"
puts "  Return URL: #{sasapay_method.preferred_return_url || 'NOT SET'}"

puts "\n🔑 Testing Authentication..."

begin
  access_token = sasapay_method.get_access_token
  
  if access_token
    puts "✅ Authentication successful!"
    puts "   Access token obtained: #{access_token[0..20]}..."
  else
    puts "❌ Authentication failed!"
    puts "   Check your CLIENT_ID and CLIENT_SECRET"
    puts "   Make sure they are correctly set in Rails credentials or environment variables"
  end
rescue => e
  puts "❌ Authentication error: #{e.message}"
  puts "   #{e.backtrace.first}"
end

puts "\n🌐 Testing API Connectivity..."

require 'net/http'
require 'uri'

base_url = sasapay_method.preferred_environment == 'production' ? 
  'https://api.sasapay.app' : 
  'https://sandbox.sasapay.app'

uri = URI("#{base_url}/api/v1/auth/token/?grant_type=client_credentials")

begin
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.read_timeout = 10
  http.open_timeout = 10
  
  request = Net::HTTP::Get.new(uri)
  request['User-Agent'] = 'Golf-n-Vibes/1.0'
  
  response = http.request(request)
  
  puts "  API Endpoint: #{uri}"
  puts "  Response Code: #{response.code}"
  puts "  Response Headers: #{response.to_hash.keys.join(', ')}"
  
  if response.code == '401'
    puts "✅ API is reachable (401 = authentication required, which is expected)"
  elsif response.code == '200'
    puts "✅ API is reachable and responding"
  else
    puts "⚠️  API responded with: #{response.code} - #{response.message}"
  end
  
rescue => e
  puts "❌ API connectivity error: #{e.message}"
end

puts "\n💡 Next Steps:"
if access_token
  puts "  1. ✅ Authentication is working"
  puts "  2. Test payment initiation via frontend"
  puts "  3. Check logs for any payment processing errors"
else
  puts "  1. ❌ Fix authentication first"
  puts "  2. Verify CLIENT_ID and CLIENT_SECRET in Rails credentials"
  puts "  3. Check SasaPay Developer Portal for correct credentials"
  puts "  4. Ensure you're using the correct environment (sandbox/production)"
end

puts "\n🔧 Configuration Commands:"
puts "  # Set credentials (development):"
puts "  EDITOR=nano rails credentials:edit"
puts "  # Or set environment variables:"
puts "  export SASAPAY_CLIENT_ID='your_client_id'"
puts "  export SASAPAY_CLIENT_SECRET='your_client_secret'"

puts "\n🏌️ Test completed!"
