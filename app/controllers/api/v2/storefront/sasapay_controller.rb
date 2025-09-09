module Api
  module V2
    module Storefront
      class SasapayController < ApplicationController
        protect_from_forgery with: :null_session
        before_action :load_order, except: [:create_order_and_pay, :create_order_with_items]
        before_action :ensure_current_store
        
        def ensure_current_store
          @current_store ||= Spree::Store.default
        end
        
        def current_store
          @current_store || ensure_current_store
        end

        # Create order with items and initiate payment - MAIN FIX METHOD
        def create_order_and_pay
          begin
            Rails.logger.info "Creating order and initiating payment with params: #{params.inspect}"
            
            # Extract parameters
            items_data = params[:items] || []
            customer_data = params[:customer_data] || {}
            payment_type = params[:payment_type] || 'mpesa_stk'
            phone_number = params[:phone_number]
            
            # Validate input
            if items_data.empty?
              render json: { 
                status: 'error', 
                message: 'No items provided',
                error_code: 'NO_ITEMS'
              }, status: :bad_request
              return
            end
            
            # Validate payment type specific requirements
            if payment_type == 'mpesa_stk' && phone_number.blank?
              render json: { 
                status: 'error', 
                message: 'Phone number required for M-Pesa',
                error_code: 'PHONE_REQUIRED'
              }, status: :bad_request
              return
            end
            
            if payment_type == 'card'
              card_data = params[:card_data]
              if card_data.blank?
                render json: { 
                  status: 'error', 
                  message: 'Card information required for card payments',
                  error_code: 'CARD_INFO_REQUIRED'
                }, status: :bad_request
                return
              end
              
              required_fields = [:card_number, :expiry_month, :expiry_year, :cvv, :cardholder_name]
              missing_fields = required_fields.select { |field| card_data[field].blank? }
              
              if missing_fields.any?
                render json: { 
                  status: 'error', 
                  message: "Missing card fields: #{missing_fields.join(', ')}",
                  error_code: 'INCOMPLETE_CARD_INFO'
                }, status: :bad_request
                return
              end
            end
            
            # Create order with line items
            total_amount = 0
            
            @order = Spree::Order.create!(
              store: current_store,
              currency: 'KES',
              email: customer_data[:email] || customer_data['email'],
              state: 'cart'
            )
            
            # Add line items
            items_data.each do |item_data|
              product_id = item_data[:product_id] || item_data['product_id']
              quantity = (item_data[:quantity] || item_data['quantity'] || 1).to_i
              
              Rails.logger.info "Processing item - Product ID: #{product_id}, Quantity: #{quantity}"
              
              # Find product by ID
              product = current_store.products.find_by(id: product_id)
              unless product
                Rails.logger.warn "Product not found: #{product_id}"
                next
              end
              
              # Use master variant
              variant = product.master
              unless variant
                Rails.logger.warn "No master variant for product: #{product_id}"
                next
              end
              
              # Create line item directly
              line_item = @order.line_items.create!(
                variant: variant,
                quantity: quantity,
                price: variant.price,
                currency: @order.currency
              )
              
              total_amount += line_item.amount
              Rails.logger.info "Added line item: #{product.name} x#{quantity} = #{line_item.amount}"
            end
            
            # Validate we have items
            if @order.line_items.count == 0
              @order.destroy
              render json: { 
                status: 'error', 
                message: 'No valid items could be added to the order',
                error_code: 'NO_VALID_ITEMS'
              }, status: :bad_request
              return
            end
            
            # Update order totals and item count using Spree's OrderUpdater
            updater = Spree::OrderUpdater.new(@order)
            updater.update
            
            # Add customer information if provided
            if customer_data.present?
              email = customer_data[:email] || customer_data['email']
              @order.update!(email: email) if email.present?
            end
            
            Rails.logger.info "Created order #{@order.number} with total: #{@order.total}"
            
            # Handle different payment types
            if payment_type == 'cod'
              # Handle Cash on Delivery
              response = handle_cash_on_delivery_complete
            else
              # Handle SasaPay payments (M-Pesa, Airtel, Card)
              sasapay_payment_method = Spree::PaymentMethod::Sasapay.active.first
              
              unless sasapay_payment_method
                render json: { 
                  status: 'error', 
                  message: 'SasaPay payment method not configured',
                  error_code: 'PAYMENT_METHOD_NOT_FOUND'
                }, status: :service_unavailable
                return
              end
              
              # Prepare payment data
              payment_data = {
                phone_number: phone_number,
                amount: @order.total,
                order_number: @order.number,
                description: "Golf n Vibes Order ##{@order.number}"
              }
              
              # Add card data if card payment
              if payment_type == 'card'
                card_data = params[:card_data]
                payment_data[:card_data] = {
                  card_number: card_data[:card_number] || card_data['card_number'],
                  expiry_month: card_data[:expiry_month] || card_data['expiry_month'], 
                  expiry_year: card_data[:expiry_year] || card_data['expiry_year'],
                  cvv: card_data[:cvv] || card_data['cvv'],
                  cardholder_name: card_data[:cardholder_name] || card_data['cardholder_name']
                }
              end
              
              # Initiate payment with SasaPay
              response = call_sasapay_api(payment_type, payment_data, sasapay_payment_method)
            end
            
            render json: response.merge({
              order_number: @order.number,
              order_total: @order.total.to_s,
              items_count: @order.line_items.count
            })
            
          rescue => e
            Rails.logger.error "Error in create_order_and_pay: #{e.message}\n#{e.backtrace.join("\n")}"
            render json: { 
              status: 'error', 
              message: "Failed to create order: #{e.message}",
              error_code: 'ORDER_CREATION_FAILED'
            }, status: :internal_server_error
          end
        end

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
    # Find both SasaPay and COD payments
    payment = @order.payments.joins(:payment_method).where(
      spree_payment_methods: { type: ['Spree::PaymentMethod::Sasapay', 'Spree::PaymentMethod::Check'] }
    ).last
    
    if payment
      # Determine payment type based on payment method
      payment_type = case payment.payment_method.type
                     when 'Spree::PaymentMethod::Sasapay'
                       'sasapay'
                     when 'Spree::PaymentMethod::Check'
                       'cod'
                     else
                       'unknown'
                     end
      
      render json: {
        order_number: @order.number,
        payment_type: payment_type,
        payment_state: payment.state,
        payment_amount: payment.amount,
        currency: @order.currency,
        order_state: @order.state,
        completed_at: @order.completed_at
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
          payment_type = params[:payment_type]
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

        # Handle other payment methods...
        def handle_airtel_money(phone_number, payment_method)
          # Implementation for Airtel Money
          render json: { status: 'error', message: 'Airtel Money not implemented yet' }
        end

        def handle_card_payment(payment_method)
          # Implementation for Card payments
          render json: { status: 'error', message: 'Card payments not implemented yet' }
        end

        def handle_cash_on_delivery(payment_method)
          # For COD, we just mark the order as pending
          render json: {
            status: 'success',
            payment_type: 'cash_on_delivery',
            message: 'Order confirmed. Payment will be collected on delivery.',
            order_number: @order.number,
            amount: @order.total
          }
        end
        
        # Handle complete Cash on Delivery order
        def handle_cash_on_delivery_complete
          begin
            Rails.logger.info "Processing COD order #{@order.number}"
            
            # Find or create Check payment method (Spree's built-in COD-like method)
            check_payment_method = Spree::PaymentMethod::Check.active.first
            unless check_payment_method
              # Create a Check payment method if none exists
              check_payment_method = Spree::PaymentMethod::Check.create!(
                name: 'Cash on Delivery',
                active: true,
                stores: [current_store]
              )
              Rails.logger.info "Created Check payment method for COD"
            end
            
            # Create a payment record in pending state
            payment = @order.payments.create!(
              payment_method: check_payment_method,
              amount: @order.total,
              state: 'pending'
            )
            Rails.logger.info "Created COD payment #{payment.id} in pending state"
            
            # Transition order to complete state
            # For COD, we complete the order but leave payment as pending
            @order.update!(
              state: 'complete',
              completed_at: Time.current,
              payment_state: 'balance_due'  # Customer still owes money
            )
            
            Rails.logger.info "COD order #{@order.number} completed successfully"
            
            {
              status: 'success',
              payment_type: 'cash_on_delivery',
              message: 'Order confirmed! Payment will be collected upon delivery.',
              order_number: @order.number,
              payment_state: 'balance_due',
              instructions: 'Your order has been confirmed. Our delivery team will collect payment when your items are delivered.'
            }
            
          rescue => e
            Rails.logger.error "Error processing COD order: #{e.message}"
            {
              status: 'error',
              message: "Failed to process cash on delivery order: #{e.message}"
            }
          end
        end

        # Make actual API call to SasaPay
        def call_sasapay_api(payment_type, payment_data, payment_method)
          Rails.logger.info "SasaPay API Call - Type: #{payment_type}, Amount: #{payment_data[:amount]}"
          
          # Get OAuth2 access token first
          access_token = get_sasapay_access_token(payment_method)
          unless access_token
            Rails.logger.error "SasaPay: Failed to get access token"
            return { status: 'error', message: 'Authentication failed' }
          end
          
          base_url = payment_method.preferred_environment == 'production' ? 
            'https://api.sasapay.app' : 
            'https://sandbox.sasapay.app'

          # Use correct SasaPay API endpoints
          endpoint = case payment_type
                    when 'mpesa_stk'
                      '/api/v1/payments/request-payment/'
                    when 'airtel_money'
                      '/api/payments/mobile-checkout/airtel/'
                    when 'card'
                      '/api/payments/card-payments/'
                    else
                      '/api/v1/payments/request-payment/'
                    end

          uri = URI("#{base_url}#{endpoint}")
          
          Rails.logger.info "SasaPay API Request: #{uri}"
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Post.new(uri)
          request['Content-Type'] = 'application/json'
          request['Authorization'] = "Bearer #{access_token}"
          
          # Prepare the request body
          merchant_code = payment_method.preferred_merchant_code || payment_method.preferred_merchant_id
          
          if payment_type == 'mpesa_stk'
            request_body = {
              MerchantCode: merchant_code,
              NetworkCode: "63902",
              PhoneNumber: payment_data[:phone_number],
              TransactionDesc: payment_data[:description],
              AccountReference: payment_data[:order_number],
              Currency: @order.currency || "KES",
              Amount: payment_data[:amount].to_s,
              CallBackURL: payment_method.preferred_callback_url || "#{request.base_url}/api/v2/storefront/sasapay/callback"
            }
          else
            request_body = {
              merchant_code: merchant_code,
              amount: payment_data[:amount],
              currency: @order.currency || "KES",
              description: payment_data[:description],
              reference: payment_data[:order_number]
            }
          end

          request.body = request_body.to_json
          Rails.logger.info "SasaPay Request Body: #{request_body.to_json}"

          begin
            response = http.request(request)
            Rails.logger.info "SasaPay Response: #{response.code} - #{response.body}"
            
            if response.code == '200' || response.code == '201'
              parsed_response = JSON.parse(response.body)
              
              {
                status: 'success',
                payment_type: payment_type,
                message: get_success_message(payment_type),
                transaction_id: parsed_response['transaction_id'] || parsed_response['reference'],
                payment_url: parsed_response['payment_url'],
                order_number: payment_data[:order_number]
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
        
        def parse_error_message(response_body)
          begin
            error_data = JSON.parse(response_body)
            error_data['message'] || error_data['error'] || 'Unknown error occurred'
          rescue JSON::ParserError
            'Payment processing failed'
          end
        end
        
        # SasaPay OAuth2 Authentication
        def get_sasapay_access_token(payment_method)
          base_url = payment_method.preferred_environment == 'production' ? 
            'https://api.sasapay.app' : 
            'https://sandbox.sasapay.app'

          uri = URI("#{base_url}/api/v1/auth/token/?grant_type=client_credentials")
          
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true

          request = Net::HTTP::Get.new(uri)
          request['Content-Type'] = 'application/json'
          
          # Get credentials from payment method preferences
          client_id = payment_method.preferred_client_id || payment_method.preferred_api_key
          client_secret = payment_method.preferred_client_secret || payment_method.preferred_api_key
          
          if client_id.blank? || client_secret.blank?
            Rails.logger.error "SasaPay Auth Error: Missing CLIENT_ID or CLIENT_SECRET"
            return nil
          end
          
          request.basic_auth(client_id, client_secret)

          begin
            Rails.logger.info "SasaPay Auth Request: #{uri}"
            
            response = http.request(request)
            Rails.logger.info "SasaPay Auth Response: #{response.code}"
            
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
            nil
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
      end
    end
  end
end
