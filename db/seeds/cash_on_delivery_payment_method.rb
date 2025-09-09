# Add Cash on Delivery payment method to Spree
Rails.logger.info "Adding Cash on Delivery payment method..."

# Get the default store
store = Spree::Store.default
raise "Default store not found" unless store

# Check if Cash on Delivery payment method already exists
cod_payment_method = Spree::PaymentMethod::CashOnDelivery.find_by(name: 'Cash on Delivery')

unless cod_payment_method
  cod_payment_method = Spree::PaymentMethod::CashOnDelivery.create!(
    name: 'Cash on Delivery',
    description: 'Pay cash when your order is delivered to your doorstep',
    active: true,
    display_on: 'both',  # Show on both frontend and backend
    position: 2,
    preferences: {
      instructions: 'Your order will be confirmed and prepared for delivery. Payment will be collected in cash when your items are delivered to your address.'
    }
  )
  
  # Associate with the store
  cod_payment_method.stores << store unless cod_payment_method.stores.include?(store)
  
  Rails.logger.info "✅ Cash on Delivery payment method created successfully!"
  Rails.logger.info "   - ID: #{cod_payment_method.id}"
  Rails.logger.info "   - Name: #{cod_payment_method.name}"
  Rails.logger.info "   - Active: #{cod_payment_method.active}"
else
  Rails.logger.info "ℹ️  Cash on Delivery payment method already exists"
  
  # Make sure it's active and properly configured
  cod_payment_method.update!(
    active: true,
    display_on: 'both',
    description: 'Pay cash when your order is delivered to your doorstep'
  )
  
  # Ensure it's associated with the store
  cod_payment_method.stores << store unless cod_payment_method.stores.include?(store)
end

Rails.logger.info "Cash on Delivery payment method setup completed!"
