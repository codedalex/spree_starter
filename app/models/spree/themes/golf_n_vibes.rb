module Spree
  module Themes
    class GolfNVibes < Spree::Theme
      def self.metadata
        {
          authors: ['Golf n Vibes Team'],
          license: 'MIT'
        }
      end

      # COLORS
      # main colors
      preference :primary_color, :string, default: '#4A7856'
      preference :accent_color, :string, default: '#80be78'
      preference :danger_color, :string, default: '#C73528'
      preference :neutral_color, :string, default: '#6B7280'
      preference :background_color, :string, default: '#FFFFFF'
      preference :text_color, :string, default: '#000000'
      preference :success_color, :string, default: '#00C773'

      # buttons
      preference :button_background_color, :string
      preference :button_text_color, :string, default: '#ffffff'
      preference :button_hover_background_color, :string
      preference :button_hover_text_color, :string
      preference :button_border_color, :string

      # borders
      preference :border_color, :string, default: '#E9E7DC'
      preference :sidebar_border_color, :string

      preference :secondary_button_background_color, :string
      preference :secondary_button_text_color, :string
      preference :secondary_button_hover_background_color, :string
      preference :secondary_button_hover_text_color, :string

      # inputs
      preference :input_text_color, :string, default: '#6b7280'
      preference :input_background_color, :string, default: '#ffffff'
      preference :input_border_color, :string
      preference :input_focus_border_color, :string
      preference :input_focus_background_color, :string
      preference :input_focus_text_color, :string

      # sidebar (checkout)
      preference :checkout_sidebar_background_color, :string, default: '#f3f4f6'
      preference :checkout_divider_background_color, :string
      preference :checkout_sidebar_text_color, :string

      # TYPOGRAPHY
      preference :custom_font_code, :string, default: nil
      # body
      preference :font_family, :string, default: 'Inter'
      preference :font_size_scale, :integer, default: 100
      # headers
      preference :header_font_family, :string, default: 'Inter'
      preference :header_font_size_scale, :integer, default: 100
      preference :headings_uppercase, :boolean, default: false

      # BUTTONS
      preference :button_border_thickness, :integer, default: 1
      preference :button_border_opacity, :integer, default: 100
      preference :button_border_radius, :integer, default: 8
      preference :button_shadow_opacity, :integer, default: 0
      preference :button_shadow_horizontal_offset, :integer, default: 0
      preference :button_shadow_vertical_offset, :integer, default: 4
      preference :button_shadow_blur, :integer, default: 5

      # INPUTS
      preference :input_border_thickness, :integer, default: 1
      preference :input_border_opacity, :integer, default: 100
      preference :input_border_radius, :integer, default: 8
      preference :input_shadow_opacity, :integer, default: 0
      preference :input_shadow_horizontal_offset, :integer, default: 0
      preference :input_shadow_vertical_offset, :integer, default: 4
      preference :input_shadow_blur, :integer, default: 5

      # BORDERS
      preference :border_width, :integer, default: 1
      preference :border_radius, :integer, default: 6
      preference :border_shadow_opacity, :integer, default: 0
      preference :border_shadow_horizontal_offset, :integer, default: 0
      preference :border_shadow_vertical_offset, :integer, default: 4
      preference :border_shadow_blur, :integer, default: 5

      # PRODUCT IMAGES
      preference :product_listing_image_height, :integer, default: 300
      preference :product_listing_image_width, :integer, default: 300
      preference :product_listing_image_height_mobile, :integer, default: 190
      preference :product_listing_image_width_mobile, :integer, default: 190

      # GOLF N VIBES SPECIFIC SETTINGS
      # Hero Section Settings
      preference :hero_title, :string, default: 'Golf n Vibes'
      preference :hero_subtitle, :string, default: ''
      preference :hero_description, :text, default: 'Experience the perfect blend of luxury golf and vibrant social experiences. Join us for unforgettable adventures on world-class courses.'
      
      # Badge Settings
      preference :hero_badge_text, :string, default: 'Premium Golf Tours'
      preference :hero_badge_enabled, :boolean, default: true
      preference :hero_badge_variant, :string, default: 'default' # default, accent, outline
      
      # Image Settings
      preference :hero_image_url, :string, default: '/images/Qatar/poster.jpg'
      
      # Layout Settings
      preference :hero_content_alignment, :string, default: 'left' # left, center, right
      preference :hero_image_position, :string, default: 'right' # left, right
      preference :hero_background_style, :string, default: 'gradient' # gradient, pattern, solid
      preference :hero_decorative_elements, :boolean, default: true
      
      # Button Settings
      preference :hero_primary_button_text, :string, default: 'Current Event'
      preference :hero_primary_button_url, :string, default: '/products'
      preference :hero_secondary_button_text, :string, default: 'Explore Past Events'
      preference :hero_secondary_button_url, :string, default: '/products'
    end
  end
end
