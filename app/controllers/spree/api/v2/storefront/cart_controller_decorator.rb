# Fix parameter handling for Cart API to prevent unpermitted parameter warnings
# The Spree V2 API expects JSON API format but Rails parameter wrapping can cause conflicts

Spree::Api::V2::Storefront::CartController.class_eval do
  # Suppress unpermitted parameter warnings for JSON API format
  # The warnings don't affect functionality but can clutter logs
  around_action :suppress_parameter_warnings, only: [:create, :update]

  private

  def suppress_parameter_warnings
    # Temporarily suppress unpermitted parameter logging
    original_log_level = ActionController::Parameters.action_on_unpermitted_parameters
    ActionController::Parameters.action_on_unpermitted_parameters = false
    
    yield
    
    ActionController::Parameters.action_on_unpermitted_parameters = original_log_level
  end
end
