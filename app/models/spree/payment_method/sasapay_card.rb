module Spree
  class PaymentMethod::SasapayCard < PaymentMethod
    # SasaPay API Credentials (from Developer Portal)
    preference :client_id, :string
    preference :client_secret, :string
    preference :merchant_code, :string
    preference :environment, :string, default: 'sandbox'
    preference :callback_url, :string
    preference :return_url, :string
    
    # Legacy support for existing configurations
    preference :merchant_id, :string
    preference :api_key, :string

    def payment_source_class
      Spree::CreditCard
    end

    def source_required?
      true
    end

    def payment_profiles_supported?
      false
    end

    def supports?(source)
      source.is_a?(Spree::CreditCard) || source.nil?
    end

    def cancel(response)
      # SasaPay doesn't support cancellation after initiation
      ActiveMerchant::Billing::Response.new(false, "SasaPay card payments cannot be cancelled", {}, {})
    end

    def capture(payment, credit_card, gateway_options)
      # SasaPay card payments are captured automatically upon successful payment
      ActiveMerchant::Billing::Response.new(true, "Card payment captured successfully", {}, {})
    end

    def void(response, gateway_options)
      # SasaPay doesn't support voiding
      ActiveMerchant::Billing::Response.new(false, "SasaPay card payments cannot be voided", {}, {})
    end

    def credit(amount, payment, response_code, gateway_options)
      # Implement refund logic if SasaPay supports it
      ActiveMerchant::Billing::Response.new(false, "Refunds not supported yet", {}, {})
    end

    def purchase(amount, credit_card, gateway_options)
      order = gateway_options[:order]
      
      begin
        response = initiate_sasapay_card_payment(amount, credit_card, order, gateway_options)
        
        if response[:success]
          ActiveMerchant::Billing::Response.new(
            true, 
            "Card payment initiated successfully", 
            response, 
            {
              authorization: response[:transaction_id],
              fraud_review: false,
              test: preferred_environment == 'sandbox'
            }
          )
        else
          ActiveMerchant::Billing::Response.new(
            false, 
            response[:message] || "Card payment failed", 
            response, 
            {}
          )
        end
      rescue => e
        Rails.logger.error "SasaPay card payment error: #{e.message}"
        ActiveMerchant::Billing::Response.new(
          false, 
          "Card payment processing error: #{e.message}", 
          {}, 
          {}
        )
      end
    end

    def authorize(amount, credit_card, gateway_options)
      # SasaPay doesn't separate authorize/capture, so we use purchase
      purchase(amount, credit_card, gateway_options)
    end

    # SasaPay OAuth2 Authentication (public method for testing)
    def get_access_token
      base_url = preferred_environment == 'production' ? 
        'https://api.sasapay.app' : 
        'https://sandbox.sasapay.app'

      uri = URI("#{base_url}/api/v1/auth/token/?grant_type=client_credentials")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri)
      request['Content-Type'] = 'application/json'
      
      # Use CLIENT_ID and CLIENT_SECRET for authentication via Basic Auth
      # Priority: use new SasaPay credentials over legacy ones
      client_id = preferred_client_id.present? ? preferred_client_id : preferred_api_key
      client_secret = preferred_client_secret.present? ? preferred_client_secret : preferred_merchant_id
      
      Rails.logger.info "SasaPay Card Auth - Using Client ID: #{client_id}"
      Rails.logger.info "SasaPay Card Auth - Client Secret present: #{client_secret.present?}"
      
      # Set Basic Authentication header
      request.basic_auth(client_id, client_secret)
      
      begin        
        response = http.request(request)
        
        Rails.logger.info "SasaPay Card Auth Response Code: #{response.code}"
        Rails.logger.info "SasaPay Card Auth Response Body: #{response.body}"
        
        if response.code == '200'
          result = JSON.parse(response.body)
          access_token = result['access_token']
          Rails.logger.info "SasaPay Card Auth Success: Token obtained"
          access_token
        else
          Rails.logger.error "SasaPay Card Auth Error: #{response.code} - #{response.body}"
          nil
        end
      rescue => e
        Rails.logger.error "SasaPay Card Auth Connection Error: #{e.message}"
        Rails.logger.error "SasaPay Card Auth Error Backtrace: #{e.backtrace.join('\n')}"
        nil
      end
    end

    private

    def initiate_sasapay_card_payment(amount, credit_card, order, gateway_options)
      # Convert amount from cents to actual currency
      amount_in_currency = (amount / 100.0).round(2)
      
      # Prepare card payment request
      payment_request = {
        amount: amount_in_currency,
        currency: order.currency,
        description: "Card Payment - Order ##{order.number}",
        orderId: order.number,
        paymentMethod: 'card',
        cardDetails: {
          cardNumber: credit_card.number,
          expiryMonth: credit_card.month.to_s.rjust(2, '0'),
          expiryYear: credit_card.year.to_s,
          cvv: credit_card.verification_value,
          cardHolderName: credit_card.name
        },
        callbackUrl: preferred_callback_url || "#{Rails.application.config.base_url}/api/v1/sasapay/callback",
        returnUrl: preferred_return_url || "#{Rails.application.config.base_url}/orders/#{order.number}"
      }

      # Add customer information if available
      if order.email.present?
        payment_request[:email] = order.email
      end

      # Make API call to SasaPay
      sasapay_response = make_sasapay_card_request(payment_request)
      
      # Store payment URL in order for redirect (if needed for 3D Secure)
      if sasapay_response[:success] && sasapay_response[:paymentUrl]
        order.update_column(:sasapay_payment_url, sasapay_response[:paymentUrl])
      end

      sasapay_response
    end

    def make_sasapay_card_request(payment_request)
      # Get access token first (SasaPay OAuth2 authentication)
      access_token = get_access_token
      return { success: false, message: 'Authentication failed' } unless access_token
      
      base_url = preferred_environment == 'production' ? 
        'https://api.sasapay.app' : 
        'https://sandbox.sasapay.app'

      # Use SasaPay Card Payment API endpoint
      uri = URI("#{base_url}/api/v1/payments/card-payment/")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{access_token}"
      
      # Format request according to SasaPay Card Payment API specification
      formatted_request = {
        MerchantCode: preferred_merchant_code || preferred_merchant_id,
        Amount: payment_request[:amount],
        Currency: payment_request[:currency],
        OrderId: payment_request[:orderId],
        Description: payment_request[:description],
        PaymentMethod: 'card',
        CardDetails: {
          CardNumber: payment_request[:cardDetails][:cardNumber],
          ExpiryMonth: payment_request[:cardDetails][:expiryMonth],
          ExpiryYear: payment_request[:cardDetails][:expiryYear],
          CVV: payment_request[:cardDetails][:cvv],
          CardHolderName: payment_request[:cardDetails][:cardHolderName]
        },
        CallbackUrl: payment_request[:callbackUrl],
        ReturnUrl: payment_request[:returnUrl]
      }
      
      # Add customer email if available
      if payment_request[:email].present?
        formatted_request[:CustomerEmail] = payment_request[:email]
      end
      
      request.body = formatted_request.to_json

      Rails.logger.info "SasaPay Card Payment Request: #{formatted_request.except(:CardDetails).to_json}"
      
      response = http.request(request)
      
      Rails.logger.info "SasaPay Card Payment Response Code: #{response.code}"
      Rails.logger.info "SasaPay Card Payment Response Body: #{response.body}"
      
      if response.code == '200'
        parsed_response = JSON.parse(response.body)
        {
          success: true,
          transaction_id: parsed_response['transactionId'],
          payment_url: parsed_response['paymentUrl'], # For 3D Secure redirects
          message: 'Card payment processed successfully'
        }
      else
        {
          success: false,
          message: "Card payment API Error: #{response.code} - #{response.body}",
          error_code: response.code
        }
      end
    rescue => e
      Rails.logger.error "SasaPay Card Payment Connection Error: #{e.message}"
      {
        success: false,
        message: "Card payment connection error: #{e.message}",
        error_code: 'CONNECTION_ERROR'
      }
    end
  end
end
