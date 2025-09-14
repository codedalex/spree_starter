# Override SSL configuration for Azure Container Instances deployment
# This disables SSL forcing when running on HTTP endpoints
if Rails.env.production? && ENV['DISABLE_SSL_REDIRECT'] == 'true'
  Rails.application.config.force_ssl = false
  Rails.application.config.assume_ssl = false
end