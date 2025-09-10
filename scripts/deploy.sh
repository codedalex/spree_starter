#!/bin/bash

# Golf n Vibes Backend Deployment Script
# This script builds and deploys the Spree backend using Docker

set -e  # Exit on any error

echo "🏌️ Golf n Vibes Backend Deployment"
echo "=================================="

# Configuration
IMAGE_NAME="golf-n-vibes/spree-backend"
CONTAINER_NAME="golf-n-vibes-backend"
NETWORK_NAME="golf-n-vibes-network"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env.production exists
if [[ ! -f .env.production ]]; then
    log_error ".env.production file not found!"
    log_info "Please copy .env.production.template to .env.production and fill in the values"
    exit 1
fi

# Load environment variables
source .env.production

# Validate required environment variables
required_vars=("DATABASE_URL" "SECRET_KEY_BASE" "CORS_ORIGINS")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        log_error "Required environment variable $var is not set"
        exit 1
    fi
done

log_info "Environment variables validated ✅"

# Step 1: Stop existing containers
log_info "Stopping existing containers..."
docker-compose -f docker-compose.production.yml down || true

# Step 2: Build the new image
log_info "Building Docker image..."
docker build -t ${IMAGE_NAME}:latest .

if [[ $? -eq 0 ]]; then
    log_info "Docker image built successfully ✅"
else
    log_error "Failed to build Docker image ❌"
    exit 1
fi

# Step 3: Run database migrations
log_info "Running database setup..."
docker-compose -f docker-compose.production.yml run --rm web bundle exec rails db:create db:migrate

if [[ $? -eq 0 ]]; then
    log_info "Database setup completed ✅"
else
    log_error "Database setup failed ❌"
    exit 1
fi

# Step 4: Load seeds if needed
read -p "Load seed data? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Loading seed data..."
    docker-compose -f docker-compose.production.yml run --rm web bundle exec rails db:seed
    docker-compose -f docker-compose.production.yml run --rm web bundle exec ruby setup_golf_products.rb
fi

# Step 5: Start services
log_info "Starting services..."
docker-compose -f docker-compose.production.yml up -d

if [[ $? -eq 0 ]]; then
    log_info "Services started successfully ✅"
else
    log_error "Failed to start services ❌"
    exit 1
fi

# Step 6: Health check
log_info "Waiting for services to be ready..."
sleep 30

# Check if web service is responding
if curl -f -s http://localhost:3000/health > /dev/null; then
    log_info "Backend health check passed ✅"
else
    log_warning "Backend health check failed ⚠️"
    log_info "Check logs with: docker-compose -f docker-compose.production.yml logs web"
fi

# Step 7: Display status
log_info "Deployment completed!"
echo
echo "📊 Service Status:"
docker-compose -f docker-compose.production.yml ps
echo
echo "🌐 Access Points:"
echo "  • API: http://localhost:3000/api/v2/storefront"
echo "  • Admin: http://localhost:3000/admin"
echo "  • Health: http://localhost:3000/health"
echo
echo "📝 Useful Commands:"
echo "  • View logs: docker-compose -f docker-compose.production.yml logs -f"
echo "  • Stop services: docker-compose -f docker-compose.production.yml down"
echo "  • Restart services: docker-compose -f docker-compose.production.yml restart"
echo
log_info "Deployment completed successfully! 🎉"
