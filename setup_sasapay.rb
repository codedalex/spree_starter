#!/usr/bin/env ruby

# SasaPay Payment Method Setup Script
puts "🏌️ Golf n Vibes - SasaPay Setup Script"
puts "=" * 50

require_relative 'config/environment'

puts "\n📊 Current Status:"
puts "  Payment Methods: #{Spree::PaymentMethod.count}"
puts "  Active Payment Methods: #{Spree::PaymentMethod.active.count}"

# Load the SasaPay seed
puts "\n🔧 Setting up SasaPay payment method..."
load Rails.root.join('db', 'seeds', 'sasapay_payment_method.rb')

puts "\n📋 Payment Methods:"
Spree::PaymentMethod.all.each do |pm|
  puts "  - #{pm.name} (#{pm.type}) - #{pm.active? ? 'Active' : 'Inactive'}"
end

# Check if SasaPay payment method is properly configured
sasapay_method = Spree::PaymentMethod.find_by(type: 'Spree::PaymentMethod::Sasapay')

if sasapay_method
  puts "\n✅ SasaPay Payment Method Configuration:"
  puts "  ID: #{sasapay_method.id}"
  puts "  Name: #{sasapay_method.name}"
  puts "  Type: #{sasapay_method.type}"
  puts "  Active: #{sasapay_method.active?}"
  puts "  Environment: #{sasapay_method.preferred_environment}"
  puts "  Merchant ID: #{sasapay_method.preferred_merchant_id}"
  puts "  Callback URL: #{sasapay_method.preferred_callback_url}"
  puts "  Return URL: #{sasapay_method.preferred_return_url}"
else
  puts "\n❌ SasaPay payment method not found!"
  puts "   Please check if the payment method class exists."
end

puts "\n🌐 API Endpoints Available:"
puts "  Payment Methods: GET /api/v2/storefront/payment_methods"
puts "  M-Pesa STK Push: POST /api/v2/storefront/sasapay/mpesa/:order_number"
puts "  Payment Status: GET /api/v2/storefront/sasapay/status/:order_number"
puts "  Payment Callback: POST /api/v2/storefront/sasapay/callback"

puts "\n🚀 SasaPay Setup Complete!"

