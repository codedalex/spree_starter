# Fix parameter handling for Cart API to prevent unpermitted parameter warnings
# The Spree V2 API expects JSON API format but Rails parameter wrapping can cause conflicts

module Spree::Api::V2::Storefront::CartControllerDecorator
  def self.prepended(base)
    base.around_action :suppress_parameter_warnings, only: [:create, :update]
  end

  private

  def suppress_parameter_warnings
    # Temporarily suppress unpermitted parameter logging
    original_log_level = ActionController::Parameters.action_on_unpermitted_parameters
    ActionController::Parameters.action_on_unpermitted_parameters = false
    
    yield
    
    ActionController::Parameters.action_on_unpermitted_parameters = original_log_level
  end
end

::Spree::Api::V2::Storefront::CartController.prepend(Spree::Api::V2::Storefront::CartControllerDecorator)
