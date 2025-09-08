require "sidekiq/web" # require the web UI

Rails.application.routes.draw do
  Spree::Core::Engine.add_routes do
    # Storefront routes
    scope '(:locale)', locale: /#{Spree.available_locales.join('|')}/, defaults: { locale: nil } do
      devise_for(
        Spree.user_class.model_name.singular_route_key,
        class_name: Spree.user_class.to_s,
        path: :user,
        controllers: {
          sessions: 'spree/user_sessions',
          passwords: 'spree/user_passwords',
          registrations: 'spree/user_registrations'
        },
        router_name: :spree
      )
    end

    # Admin authentication
    devise_for(
      Spree.admin_user_class.model_name.singular_route_key,
      class_name: Spree.admin_user_class.to_s,
      controllers: {
        sessions: 'spree/admin/user_sessions',
        passwords: 'spree/admin/user_passwords'
      },
      skip: :registrations,
      path: :admin_user,
      router_name: :spree
    )
  end
  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to
  # Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the
  # :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being
  # the default of "spree".
  mount Spree::Core::Engine, at: '/'

  # Custom API routes for storefront
  namespace :api do
    namespace :v2 do
      namespace :storefront do
        # Payment methods endpoint
        resources :payment_methods, only: [:index]
        
        # SasaPay payment routes
        resources :sasapay, only: [] do
          collection do
            post :callback
            get 'status/:order_number', action: :status, as: :status
            post 'mpesa/:order_number', action: :mpesa_stk_push, as: :mpesa_stk_push
            post 'payment/:order_number', action: :initiate_payment, as: :initiate_payment
            # New endpoint for creating order with items and initiating payment
            post 'create_order_and_pay', action: :create_order_and_pay, as: :create_order_and_pay
          end
        end
      end
    end
  end

  mount Sidekiq::Web => "/sidekiq" # access it at http://localhost:3000/sidekiq

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/") - redirect to admin for headless setup
  root "spree/admin/orders#index"
end
