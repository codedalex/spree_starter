# Create SasaPay payment method
sasapay_payment_method = Spree::PaymentMethod::Sasapay.find_or_create_by!(name: 'SasaPay') do |pm|
  pm.description = 'Pay with M-Pesa, Airtel Money, and other mobile money services via SasaPay'
  pm.active = true
  pm.display_on = 'both'  # Show on both frontend and backend
  pm.auto_capture = true  # Automatically capture payments
end

# Set preferences (following official SasaPay documentation)
sasapay_payment_method.update!(
  preferences: {
    # Official SasaPay API Credentials (from Developer Portal)
    client_id: Rails.application.credentials.dig(:sasapay, :client_id) || ENV['SASAPAY_CLIENT_ID'] || 'demo_client_id',
    client_secret: Rails.application.credentials.dig(:sasapay, :client_secret) || ENV['SASAPAY_CLIENT_SECRET'] || 'demo_client_secret',
    merchant_code: Rails.application.credentials.dig(:sasapay, :merchant_code) || ENV['SASAPAY_MERCHANT_CODE'] || 'demo_merchant_code',
    
    # Legacy support for existing configurations
    merchant_id: Rails.application.credentials.dig(:sasapay, :merchant_id) || 'demo_merchant_id',
    api_key: Rails.application.credentials.dig(:sasapay, :api_key) || 'demo_api_key',
    
    environment: Rails.env.production? ? 'production' : 'sandbox',
    callback_url: "http://localhost:3001/api/v2/storefront/sasapay/callback",
    return_url: "http://localhost:3000/checkout/complete"
  }
)

puts "✅ SasaPay payment method created/updated successfully"
puts "   Merchant ID: #{sasapay_payment_method.preferred_merchant_id}"
puts "   Environment: #{sasapay_payment_method.preferred_environment}"
puts "   Callback URL: #{sasapay_payment_method.preferred_callback_url}"
