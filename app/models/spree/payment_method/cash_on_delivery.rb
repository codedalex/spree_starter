class Spree::PaymentMethod::CashOnDelivery < Spree::PaymentMethod
  preference :instructions, :text, default: 'Payment will be collected upon delivery'
  
  def payment_source_class
    nil
  end

  def source_required?
    false
  end

  def auto_capture?
    false
  end

  def supports?(source)
    true
  end

  def can_void?(payment)
    payment.state == 'pending'
  end

  def can_capture?(payment)
    payment.state == 'pending'
  end

  def actions
    %w{capture void}
  end

  # For COD, we don't process payment immediately
  # Payment is marked as pending and captured when delivered
  def authorize(amount, source, gateway_options = {})
    ActiveMerchant::Billing::Response.new(
      true,
      'Cash on Delivery authorized',
      {},
      authorization: "COD-#{Time.current.to_i}",
      test: !Rails.env.production?
    )
  end

  def capture(amount, authorization, gateway_options = {})
    ActiveMerchant::Billing::Response.new(
      true,
      'Cash on Delivery payment captured',
      {},
      authorization: authorization,
      test: !Rails.env.production?
    )
  end

  def void(authorization, gateway_options = {})
    ActiveMerchant::Billing::Response.new(
      true,
      'Cash on Delivery payment voided',
      {},
      authorization: authorization,
      test: !Rails.env.production?
    )
  end

  def payment_profiles_supported?
    false
  end

  def credit(amount, authorization, gateway_options = {})
    ActiveMerchant::Billing::Response.new(
      false,
      'Cash on Delivery does not support refunds',
      {}
    )
  end

  def partial_name
    'cash_on_delivery'
  end

  def method_type
    'cash_on_delivery'
  end
end
