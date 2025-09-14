# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Golf n Vibes is a Spree Commerce 5.1 e-commerce application built with Ruby on Rails 8.0. It's a golf-focused marketplace featuring custom theming, multi-payment integration (Stripe, PayPal, SasaPay), and API endpoints for headless commerce.

**Technology Stack:**
- Ruby 3.3.0 with Rails 8.0
- Spree Commerce 5.1 (open-source e-commerce platform)
- PostgreSQL database with Redis for caching/sessions
- Sidekiq for background jobs
- Tailwind CSS with custom Golf n Vibes theme
- Docker support with docker-compose

## Common Development Commands

### Setup and Development Server
```powershell
# Initial setup (installs dependencies, prepares DB, seeds data)
.\bin\setup

# Start development server with all services (preferred method)
bundle exec foreman start -f Procfile.dev

# Alternative: Start Rails server only (runs on port 3001)
bundle exec rails server -p 3001

# Start individual services manually
bundle exec rails server -p 3001  # Web server
bundle exec sidekiq                # Background jobs
bundle exec rails dartsass:watch   # Admin CSS compilation
bundle exec rails tailwindcss:watch # Storefront CSS compilation
```

### Database Operations
```powershell
# Database setup and migrations
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

# Load sample data and Golf n Vibes products
ruby setup_golf_products.rb

# Reset database (development)
bundle exec rails db:drop db:create db:migrate db:seed

# Check database status
bundle exec rails runner "puts 'Products: ' + Spree::Product.count.to_s"
```

### Testing
```powershell
# Run full test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/spree/product_spec.rb

# Run tests with documentation format
bundle exec rspec --format documentation

# Run tests for specific functionality
bundle exec rspec spec/controllers/spree/api/v2/storefront/sasapay_controller_spec.rb
```

### Code Quality and Linting
```powershell
# Run RuboCop for code style checking
bundle exec rubocop

# Auto-fix RuboCop violations where possible
bundle exec rubocop --auto-correct

# Run security analysis
bundle exec brakeman

# Run in Rails console for debugging
bundle exec rails console
```

### Docker Development
```powershell
# Start PostgreSQL and Redis services
docker-compose up postgres redis

# Start all services including Rails app
docker-compose -f docker-compose.production.yml up
```

## Architecture and Code Structure

### Spree Commerce Integration
This application extends Spree Commerce core functionality with custom:
- **Admin Controllers**: `app/controllers/spree/admin/` - Custom admin interfaces
- **API Controllers**: `app/controllers/api/v2/storefront/` - RESTful API endpoints
- **Payment Methods**: `app/models/spree/payment_method/` - SasaPay integration
- **Theme System**: `app/assets/themes/golf_n_vibes/` - Custom Golf n Vibes theme

### Key Architectural Components

**Theme Architecture (Golf n Vibes)**:
- Theme manifest: `app/assets/themes/golf_n_vibes/manifest.json`
- Layout overrides: `app/views/layouts/spree/storefront/application.html.erb`
- Custom templates: `app/views/spree/storefront/home/index.html.erb`
- Theme helpers: `app/helpers/spree/storefront/golf_n_vibes_helper.rb`

**API Structure**:
- Follows Spree V2 API conventions under `/api/v2/storefront/`
- SasaPay payment integration with callback handling
- CORS configured for headless commerce (see `config/application.rb`)

**Payment Integration**:
- Multiple gateways: Stripe (`spree_stripe`), PayPal (`spree_paypal_checkout`), SasaPay (custom)
- SasaPay controller handles M-Pesa STK Push and callback processing
- Payment method models in `app/models/spree/payment_method/`

**Background Jobs**:
- Sidekiq for asynchronous processing
- Jobs likely handle payment callbacks, email notifications
- Web UI accessible at `http://localhost:3001/sidekiq`

### Configuration Management
- **Environment Variables**: Uses `.env` files for development, see `.env.production.example` for production vars
- **Spree Settings**: Theme customization through Spree's preference system
- **CORS Origins**: Configured in `config/application.rb` for multiple domains including `golfnvibes.com`

## Development Workflow

### Making Theme Changes
```powershell
# Modify theme files in app/assets/themes/golf_n_vibes/
# Changes to CSS/JS require asset recompilation:
bundle exec rails dartsass:watch    # For admin styles
bundle exec rails tailwindcss:watch # For storefront styles

# Theme settings can be modified via Rails console:
bundle exec rails console
# Then: GolfNVibesTheme.config.hero_title = "New Title"
```

### Custom Payment Gateway Development
When working with SasaPay or adding new payment methods:
- Controllers: `app/controllers/api/v2/storefront/sasapay_controller.rb`
- Models: `app/models/spree/payment_method/`
- Routes: Custom API routes defined in `config/routes.rb` under `/api/v2/storefront/sasapay`

### API Development
- Follow Spree V2 API patterns and serialization
- Test API endpoints: `http://localhost:3001/api/v2/storefront/products`
- Use Spree's built-in authentication for protected endpoints

## Important Application-Specific Notes

### Port Configuration
- **Backend (Spree)**: Runs on port 3001 (configured in `Procfile.dev`)
- **Frontend**: Separate Next.js app likely runs on port 3000
- **Database**: PostgreSQL on port 5432, Redis on port 6379

### Golf n Vibes Theme System
- Theme is integrated with Spree's admin interface for customization
- Hero section is fully customizable through admin panel
- Uses CSS custom properties for dynamic theme colors
- Mobile-responsive with golf-themed decorative elements

### SasaPay Integration
- Handles M-Pesa payments for Kenyan market
- STK Push implementation for mobile money
- Callback URL handling for payment status updates
- Order creation with payment initiation in single API call

### Database Schema
- Standard Spree Commerce schema with custom extensions
- Products configured for golf-related items (tours, equipment, experiences)
- Custom taxonomies for golf categories

### Deployment Considerations
- Multiple deployment targets: Azure, Railway, Render (see deployment guides)
- Environment-specific database configurations
- Asset precompilation required for production
- Background job processing with Sidekiq in production

## Testing Strategy

### Test Files Location
- **RSpec specs**: `spec/` directory
- **Factories**: Uses Spree dev tools and custom factories
- **Test helpers**: Spree-specific test configuration in `spec/spec_helper.rb`

### Key Areas to Test
- Payment gateway integrations (especially SasaPay callbacks)
- Theme customization functionality
- API endpoint responses and serialization
- Admin interface customizations
- Background job processing

### Test Environment Setup
- Uses separate test database: `spree_starter_test`
- Sidekiq testing mode configured
- Test environment loads from `.env` file

This codebase requires understanding of Spree Commerce conventions and Ruby on Rails patterns. The custom theming system and payment integrations are the most complex components requiring careful attention during development.