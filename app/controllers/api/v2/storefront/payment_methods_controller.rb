module Api
  module V2
    module Storefront
      class PaymentMethodsController < ApplicationController
        protect_from_forgery with: :null_session
        before_action :ensure_current_store

        def index
          payment_methods = current_store.payment_methods.active.available_on_front_end.map do |pm|
            {
              id: pm.id,
              name: pm.name,
              type: pm.type,
              description: pm.description
            }
          end

          render json: {
            data: payment_methods,
            count: payment_methods.length
          }
        end

        private

        def ensure_current_store
          @current_store ||= Spree::Store.current(request.host)
        end

        def current_store
          @current_store
        end
      end
    end
  end
end