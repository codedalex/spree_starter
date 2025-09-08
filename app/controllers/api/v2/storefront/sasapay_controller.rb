module Api
  module V2
    module Storefront
      class SasapayController < ApplicationController
        protect_from_forgery with: :null_session
        before_action :load_order

          # Handle SasaPay payment callback
          def callback
            Rails.logger.info "SasaPay Callback received: #{params.inspect}"

            begin
              # Verify the callback authenticity (implement based on SasaPay documentation)
              if verify_sasapay_callback
                # Update payment status
                payment = @order.payments.where(payment_method_type: 'Spree::PaymentMethod::Sasapay').last
                
                if payment && params[:status] == 'success'
                  payment.complete!
                  @order.next! if @order.can_complete?
                  
                  render json: { 
                    status: 'success', 
                    message: 'Payment confirmed successfully' 
                  }
                else
                  payment&.failure! if payment
                  render json: { 
                    status: 'failed', 
                    message: 'Payment confirmation failed' 
                  }
                end
              else
                render json: { 
                  status: 'error', 
                  message: 'Invalid callback signature' 
                }, status: :unauthorized
              end
            rescue => e
              Rails.logger.error "SasaPay callback error: #{e.message}"
              render json: { 
                status: 'error', 
                message: 'Internal server error' 
              }, status: :internal_server_error
            end
          end

          # Handle payment status check
          def status
            payment = @order.payments.where(payment_method_type: 'Spree::PaymentMethod::Sasapay').last
            
            if payment
              render json: {
                order_number: @order.number,
                payment_state: payment.state,
                payment_amount: payment.amount,
                currency: @order.currency
              }
            else
              render json: { 
                status: 'error', 
                message: 'Payment not found' 
              }, status: :not_found
            end
          end

          # Initiate payment with SasaPay (supports multiple payment methods)
          def initiate_payment
            payment_type = params[:payment_type] # 'mpesa_stk', 'airtel_money', 'card', 'cod'
            phone_number = params[:phone_number]
            
            # Get the SasaPay payment method
            sasapay_payment_method = Spree::PaymentMethod::Sasapay.active.first
            
            if sasapay_payment_method.blank?
              render json: { 
                status: 'error', 
                message: 'SasaPay payment method not configured' 
              }, status: :service_unavailable
              return
            end

            begin
              case payment_type
              when 'mpesa_stk'
                handle_mpesa_stk_push(phone_number, sasapay_payment_method)
              when 'airtel_money'
                handle_airtel_money(phone_number, sasapay_payment_method)
              when 'card'
                handle_card_payment(sasapay_payment_method)
              when 'cod'
                handle_cash_on_delivery(sasapay_payment_method)
              else
                render json: { 
                  status: 'error', 
                  message: 'Invalid payment type' 
                }, status: :bad_request
              end
            rescue => e
              Rails.logger.error "SasaPay payment error: #{e.message}"
              render json: { 
                status: 'error', 
                message: 'Failed to process payment' 
              }, status: :internal_server_error
            end
          end

          # Legacy M-Pesa STK Push endpoint (for backward compatibility)
          def mpesa_stk_push
            phone_number = params[:phone_number]
            
            if phone_number.blank?
              render json: { 
                status: 'error', 
                message: 'Phone number is required' 
              }, status: :bad_request
              return
            end

            # Get the SasaPay payment method
            sasapay_payment_method = Spree::PaymentMethod::Sasapay.active.first
            
            if sasapay_payment_method.blank?
              render json: { 
                status: 'error', 
                message: 'SasaPay payment method not configured' 
              }, status: :service_unavailable
              return
            end

            begin
              handle_mpesa_stk_push(phone_number, sasapay_payment_method)
            rescue => e
              Rails.logger.error "M-Pesa STK Push error: #{e.message}"
              render json: { 
                status: 'error', 
                message: 'Failed to process M-Pesa payment' 
              }, status: :internal_server_error
            end
          end

          private

          def load_order
            @order = Spree::Order.find_by(number: params[:order_number])
            
            unless @order
              render json: { 
                status: 'error', 
                message: 'Order not found' 
              }, status: :not_found
              return
            end
          end

          def verify_sasapay_callback
            # Implement SasaPay signature verification based on their documentation
            # This is a simplified version - implement proper verification
            signature = request.headers['X-SasaPay-Signature']
            
            if signature.present?
              # Verify signature logic here
              # For now, we'll accept all callbacks (NOT RECOMMENDED FOR PRODUCTION)
              true
            else
              false
            end
          end

          def format_kenyan_phone(phone)
            # Remove all non-digits
            formatted = phone.gsub(/\D/, '')
            
            # Convert to international format
            if formatted.start_with?('0')
              formatted = '254' + formatted[1..-1]
            elsif formatted.start_with?('7') || formatted.start_with?('1')
              formatted = '254' + formatted
            end
            
            formatted
          end

          # Handle M-Pesa STK Push via SasaPay API
          def handle_mpesa_stk_push(phone_number, payment_method)
            if phone_number.blank?
              render json: { 
                status: 'error', 
                message: 'Phone number is required for M-Pesa payments' 
              }, status: :bad_request
              return
            end

            # Debug logging
            Rails.logger.info "Order Debug - Number: #{@order.number}, Total: #{@order.total}, Currency: #{@order.currency}"
            Rails.logger.info "Order Debug - Items count: #{@order.line_items.count}"
            
            # Validate order has items
            if @order.line_items.count == 0
              render json: { 
                status: 'error', 
                message: 'Your cart is empty. Please add items to your cart before proceeding with payment.',
                order_total: @order.total,
                items_count: @order.line_items.count,
                error_code: 'EMPTY_CART'
              }, status: :bad_request
              return
            end
            
            # Validate order amount
            if @order.total <= 0
              render json: { 
                status: 'error', 
                message: 'Order total must be greater than KES 0. Please add items to your cart before proceeding with payment.',
                order_total: @order.total,
                items_count: @order.line_items.count,
                error_code: 'ZERO_TOTAL'
              }, status: :bad_request
              return
            end
            
            # Validate minimum amount (SasaPay requirement)
            if @order.total < 1
              render json: { 
                status: 'error', 
                message: 'Minimum payment amount is KES 1. Please ensure your order total meets this requirement.',
                order_total: @order.total,
                minimum_required: 1
              }, status: :bad_request
              return
            end

            formatted_phone = format_kenyan_phone(phone_number)
            response = call_sasapay_api('mpesa_stk', {
              phone_number: formatted_phone,
              amount: @order.total,
              order_number: @order.number,
              description: "Golf n Vibes Order ##{@order.number}"
            }, payment_method)

            render json: response
          end

          # Handle Airtel Money via SasaPay API
          def handle_airtel_money(phone_number, payment_method)
            if phone_number.blank?
              render json: { 
                status: 'error', 
                message: 'Phone number is required for Airtel Money payments' 
              }, status: :bad_request
              return
            end

            formatted_phone = format_kenyan_phone(phone_number)
            response = call_sasapay_api('airtel_money', {
              phone_number: formatted_phone,
              amount: @order.total,
              order_number: @order.number,
              description: "Golf n Vibes Order ##{@order.number}"
            }, payment_method)

            render json: response
          end

          # Handle Card payments via SasaPay API
          def handle_card_payment(payment_method)
            response = call_sasapay_api('card', {
              amount: @order.total,
              order_number: @order.number,
              description: "Golf n Vibes Order ##{@order.number}",
              return_url: payment_method.preferred_return_url,
              callback_url: payment_method.preferred_callback_url
            }, payment_method)

            render json: response
          end

          # Handle Cash on Delivery
          def handle_cash_on_delivery(payment_method)
            # For COD, we just mark the order as pending and don't call external API
            render json: {
              status: 'success',
              payment_type: 'cash_on_delivery',
              message: 'Order confirmed. Payment will be collected on delivery.',
              order_number: @order.number,
              amount: @order.total
            }
          end

          # Make actual API call to SasaPay
          def call_sasapay_api(payment_type, payment_data, payment_method)
            # Get OAuth2 access token first
            access_token = get_sasapay_access_token(payment_method)
            return { status: 'error', message: 'Authentication failed' } unless access_token
            
            base_url = payment_method.preferred_environment == 'production' ? 
              'https://api.sasapay.app' : 
              'https://sandbox.sasapay.app'

            # Use correct SasaPay API endpoints based on the working implementation
            endpoint = case payment_type
                      when 'mpesa_stk'
                        '/api/v1/payments/request-payment/'  # Working M-PESA STK endpoint from NestJS code
                      when 'airtel_money'
                        '/api/payments/mobile-checkout/airtel/'  # Working Airtel Money endpoint
                      when 'card'
                        '/api/payments/card-payments/'           # Working Card payments endpoint
                      else
                        '/api/v1/payments/request-payment/'      # Default payment endpoint
                      end

            uri = URI("#{base_url}#{endpoint}")
            
            Rails.logger.info "SasaPay API Call: #{uri}"
            Rails.logger.info "SasaPay Payment Type: #{payment_type}"
            
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Post.new(uri)
            request['Content-Type'] = 'application/json'
            request['Authorization'] = "Bearer #{access_token}"
            
            # Prepare the request body according to SasaPay API specification
            merchant_code = payment_method.preferred_merchant_code || payment_method.preferred_merchant_id
            
            if payment_type == 'mpesa_stk'
              # M-PESA STK Push request format (based on working implementation)
              request_body = {
                MerchantCode: merchant_code,
                NetworkCode: "63902", # M-PESA network code
                PhoneNumber: payment_data[:phone_number],
                TransactionDesc: payment_data[:description],
                AccountReference: payment_data[:order_number],
                Currency: @order.currency || "KES",
                Amount: payment_data[:amount].to_s,
                CallBackURL: payment_method.preferred_callback_url || "#{request.base_url}/api/v2/storefront/sasapay/callback"
              }
            elsif payment_type == 'airtel_money'
              # Airtel Money request format
              request_body = {
                merchant_code: merchant_code,
                mobile_number: payment_data[:phone_number],
                amount: payment_data[:amount],
                currency_code: @order.currency || "KES",
                narration: payment_data[:description],
                transaction_reference: payment_data[:order_number],
                call_back_url: payment_method.preferred_callback_url || "#{request.base_url}/api/v2/storefront/sasapay/callback"
              }
            else
              # Card/Hosted checkout request format (based on working implementation)
              request_body = {
                MerchantCode: merchant_code,
                Amount: payment_data[:amount],
                Reference: payment_data[:order_number],
                Description: payment_data[:description],
                Currency: @order.currency || "KES",
                PayerEmail: @order.email || "customer@golfnvibes.com",
                CallbackUrl: payment_method.preferred_callback_url || "#{request.base_url}/api/v2/storefront/sasapay/callback",
                RedirectUrl: payment_method.preferred_return_url || "#{request.base_url}/orders/#{@order.number}",
                SuccessUrl: payment_method.preferred_return_url || "#{request.base_url}/orders/#{@order.number}?status=success",
                FailureUrl: payment_method.preferred_return_url || "#{request.base_url}/orders/#{@order.number}?status=failed",
                CardEnabled: true,
                MpesaEnabled: true,
                SasaPayWalletEnabled: true,
                AirtelEnabled: false
              }
            end

            request.body = request_body.to_json

            begin
              response = http.request(request)
              
              if response.code == '200' || response.code == '201'
                parsed_response = JSON.parse(response.body)
                
                {
                  status: 'success',
                  payment_type: payment_type,
                  message: get_success_message(payment_type),
                  transaction_id: parsed_response['transaction_id'] || parsed_response['reference'],
                  payment_url: parsed_response['payment_url'],
                  order_number: @order.number
                }
              else
                Rails.logger.error "SasaPay API Error: #{response.code} - #{response.body}"
                {
                  status: 'failed',
                  message: "Payment failed: #{parse_error_message(response.body)}",
                  error_code: response.code
                }
              end
            rescue => e
              Rails.logger.error "SasaPay API Connection Error: #{e.message}"
              {
                status: 'error',
                message: "Payment service temporarily unavailable. Please try again.",
                error_code: 'CONNECTION_ERROR'
              }
            end
          end

          def get_success_message(payment_type)
            case payment_type
            when 'mpesa_stk'
              'M-Pesa payment request sent to your phone. Please enter your PIN to complete the transaction.'
            when 'airtel_money'
              'Airtel Money payment request sent to your phone. Please authorize the transaction.'
            when 'card'
              'Redirecting to secure card payment page.'
            else
              'Payment initiated successfully.'
            end
          end

          def parse_error_message(response_body)
            begin
              error_data = JSON.parse(response_body)
              error_data['message'] || error_data['error'] || 'Unknown error occurred'
            rescue JSON::ParserError
              'Payment processing failed'
            end
          end

          def initiate_mpesa_payment(phone_number, order, payment_method)
            # Legacy method - now uses the new handle_mpesa_stk_push approach
            formatted_phone = format_kenyan_phone(phone_number)
            call_sasapay_api('mpesa_stk', {
              phone_number: formatted_phone,
              amount: order.total,
              order_number: order.number,
              description: "Golf n Vibes Order ##{order.number}"
            }, payment_method)
          end

          # SasaPay OAuth2 Authentication (following official documentation)
          def get_sasapay_access_token(payment_method)
            base_url = payment_method.preferred_environment == 'production' ? 
              'https://api.sasapay.app' : 
              'https://sandbox.sasapay.app'

            uri = URI("#{base_url}/api/v1/auth/token/?grant_type=client_credentials")
            
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true

            request = Net::HTTP::Get.new(uri)
            request['Content-Type'] = 'application/json'
            
            # Use CLIENT_ID and CLIENT_SECRET from SasaPay Developer Portal
            # TEMPORARY FIX: The real CLIENT_ID is stored in merchant_id due to admin configuration confusion
            # Check if client_id looks like an app name instead of an actual API CLIENT_ID
            if payment_method.preferred_client_id.present? && payment_method.preferred_client_id =~ /^[a-zA-Z\s]+$/
              # If client_id looks like "Golf N Vibes", use merchant_id as the real CLIENT_ID
              client_id = payment_method.preferred_merchant_id
              Rails.logger.warn "SasaPay: Using merchant_id field as CLIENT_ID because client_id field contains app name ('#{payment_method.preferred_client_id}')"
            else
              client_id = payment_method.preferred_client_id || payment_method.preferred_api_key
            end
            client_secret = payment_method.preferred_client_secret || payment_method.preferred_api_key
            
            # Validate credentials format
            if client_id.blank? || client_secret.blank?
              Rails.logger.error "SasaPay Auth Error: Missing CLIENT_ID or CLIENT_SECRET"
              return nil
            end
            
            # Set Basic Authentication header (as per SasaPay documentation)
            request.basic_auth(client_id, client_secret)

            begin
              Rails.logger.info "SasaPay Auth Request: #{uri}"
              Rails.logger.info "SasaPay Auth Client ID: #{client_id}"
              
              response = http.request(request)
              
              Rails.logger.info "SasaPay Auth Response Code: #{response.code}"
              Rails.logger.info "SasaPay Auth Response Body: #{response.body}"
              
              if response.code == '200'
                parsed_response = JSON.parse(response.body)
                access_token = parsed_response['access_token']
                Rails.logger.info "SasaPay Auth Success: Token obtained"
                access_token
              else
                Rails.logger.error "SasaPay Auth Error: #{response.code} - #{response.body}"
                nil
              end
            rescue => e
              Rails.logger.error "SasaPay Auth Connection Error: #{e.message}"
              Rails.logger.error "SasaPay Auth Error Backtrace: #{e.backtrace.join('\n')}"
              nil
            end
          end
        end
      end
    end
  end
