# Fix pagination parameter issues for Spree API
# This decorator handles the parameter format mismatch between frontend and Kaminari

Spree::Api::V2::Storefront::ProductsController.class_eval do
  private
  
  # Override the page method to extract page number correctly
  def page
    # Handle different parameter structures
    if params[:page].is_a?(Hash)
      # If page is a hash like {"size" => "4"}, default to page 1
      1
    elsif params[:page].present?
      # If page is provided as a simple value, use it
      params[:page].to_i
    else
      # Default to page 1
      1
    end
  end
  
  # Override the per_page method to handle size parameter correctly
  def per_page
    # Check various parameter formats for per_page information
    if params[:per_page].present?
      params[:per_page].to_i
    elsif params[:page].is_a?(Hash) && params[:page][:size].present?
      params[:page][:size].to_i
    else
      # Use a reasonable default per page value
      25
    end
  end
end
