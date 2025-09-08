#!/usr/bin/env ruby

# Test script to check if SasaPay controller loads correctly
require_relative 'config/environment'

puts "🧪 Testing SasaPay Controller Load"
puts "=" * 40

begin
  # Try to load the controller
  controller_class = Api::V2::Storefront::SasapayController
  puts "✅ Controller class loaded: #{controller_class}"
  
  # Check if methods exist
  methods_to_check = [:initiate_payment, :mpesa_stk_push, :status, :callback]
  
  methods_to_check.each do |method|
    if controller_class.instance_methods.include?(method)
      puts "✅ Method #{method} exists"
    else
      puts "❌ Method #{method} missing"
    end
  end
  
  puts "\n📋 All instance methods in controller:"
  controller_class.instance_methods(false).each do |method|
    puts "  - #{method}"
  end
  
rescue => e
  puts "❌ Error loading controller: #{e.message}"
  puts e.backtrace.first(5)
end

# Test SasaPay payment method
begin
  sasapay_method = Spree::PaymentMethod::Sasapay.active.first
  if sasapay_method
    puts "\n✅ SasaPay payment method found:"
    puts "   ID: #{sasapay_method.id}"
    puts "   Name: #{sasapay_method.name}"
    puts "   Active: #{sasapay_method.active?}"
  else
    puts "\n❌ No active SasaPay payment method found"
  end
rescue => e
  puts "\n❌ Error checking payment method: #{e.message}"
end

