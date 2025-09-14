# Azure Deployment Script for Golf N Vibes Spree Commerce
# Run this script when network connectivity is available

Write-Host "🏌️ Starting Azure Deployment for Golf N Vibes" -ForegroundColor Green

# Configuration
$ResourceGroup = "golf-n-vibes-rg"
$Location = "East US"  # Fallback from Switzerland North if student restrictions
$AppServicePlan = "golf-n-vibes-plan"
$WebAppName = "golf-n-vibes-spree"
$ContainerRegistry = "golfnvibesacr"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $ResourceGroup"
Write-Host "  Location: $Location"
Write-Host "  App Service Plan: $AppServicePlan"
Write-Host "  Web App: $WebAppName"
Write-Host ""

# Step 1: Create Resource Group
Write-Host "1️⃣ Creating Resource Group..." -ForegroundColor Cyan
try {
    az group create --name $ResourceGroup --location $Location
    Write-Host "✅ Resource Group created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Resource Group. Error: $_" -ForegroundColor Red
    Write-Host "💡 Trying alternative region..." -ForegroundColor Yellow
    az group create --name $ResourceGroup --location "Switzerland North"
}

# Step 2: Create Container Registry
Write-Host "2️⃣ Creating Container Registry..." -ForegroundColor Cyan
try {
    az acr create --resource-group $ResourceGroup --name $ContainerRegistry --sku Basic --location $Location
    Write-Host "✅ Container Registry created successfully" -ForegroundColor Green
    
    # Enable admin user
    az acr update --name $ContainerRegistry --admin-enabled true
    Write-Host "✅ Admin user enabled for Container Registry" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Container Registry. Error: $_" -ForegroundColor Red
}

# Step 3: Get Container Registry Credentials
Write-Host "3️⃣ Getting Container Registry Credentials..." -ForegroundColor Cyan
$RegistryCredentials = az acr credential show --name $ContainerRegistry --resource-group $ResourceGroup | ConvertFrom-Json
$RegistryUsername = $RegistryCredentials.username
$RegistryPassword = $RegistryCredentials.passwords[0].value

Write-Host "📝 Registry Credentials (save these for GitHub Secrets):" -ForegroundColor Yellow
Write-Host "  REGISTRY_LOGIN_SERVER: $ContainerRegistry.azurecr.io"
Write-Host "  REGISTRY_USERNAME: $RegistryUsername"
Write-Host "  REGISTRY_PASSWORD: [Hidden - check Azure Portal]"
Write-Host ""

# Step 4: Create App Service Plan
Write-Host "4️⃣ Creating App Service Plan..." -ForegroundColor Cyan
try {
    az appservice plan create --name $AppServicePlan --resource-group $ResourceGroup --location $Location --sku B1 --is-linux
    Write-Host "✅ App Service Plan created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create App Service Plan. Error: $_" -ForegroundColor Red
}

# Step 5: Create Web App
Write-Host "5️⃣ Creating Web App..." -ForegroundColor Cyan
try {
    az webapp create --resource-group $ResourceGroup --plan $AppServicePlan --name $WebAppName --deployment-container-image-name "$ContainerRegistry.azurecr.io/spree-golf:latest"
    Write-Host "✅ Web App created successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create Web App. Error: $_" -ForegroundColor Red
}

# Step 6: Configure Container Settings
Write-Host "6️⃣ Configuring Container Settings..." -ForegroundColor Cyan
try {
    az webapp config container set --name $WebAppName --resource-group $ResourceGroup --docker-custom-image-name "$ContainerRegistry.azurecr.io/spree-golf:latest" --docker-registry-server-url "https://$ContainerRegistry.azurecr.io" --docker-registry-server-user $RegistryUsername --docker-registry-server-password $RegistryPassword
    Write-Host "✅ Container settings configured successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to configure container settings. Error: $_" -ForegroundColor Red
}

# Step 7: Generate Secret Key Base
Write-Host "7️⃣ Generating Rails Secret Key..." -ForegroundColor Cyan
$SecretKeyBase = -join ((1..128) | ForEach { [char](Get-Random -Min 97 -Max 123) })
Write-Host "📝 SECRET_KEY_BASE: $SecretKeyBase" -ForegroundColor Yellow
Write-Host ""

# Step 8: Configure Environment Variables
Write-Host "8️⃣ Configuring Environment Variables..." -ForegroundColor Cyan
try {
    az webapp config appsettings set --resource-group $ResourceGroup --name $WebAppName --settings `
        RAILS_ENV=production `
        SECRET_KEY_BASE="$SecretKeyBase" `
        RAILS_SERVE_STATIC_FILES=true `
        RAILS_LOG_TO_STDOUT=true `
        FORCE_SSL=false `
        SPREE_ADMIN_EMAIL=admin@golfnvibes.com `
        SPREE_ADMIN_PASSWORD=GolfNVibes2024! `
        STORE_NAME="Golf N Vibes" `
        STORE_EMAIL=info@golfnvibes.com
    
    Write-Host "✅ Environment variables configured successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to configure environment variables. Error: $_" -ForegroundColor Red
}

# Step 9: Create Service Principal for GitHub Actions
Write-Host "9️⃣ Creating Service Principal for GitHub Actions..." -ForegroundColor Cyan
try {
    $SubscriptionId = (az account show | ConvertFrom-Json).id
    $ServicePrincipal = az ad sp create-for-rbac --name "golf-n-vibes-github" --role contributor --scopes "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup" --sdk-auth | ConvertFrom-Json
    
    Write-Host "📝 GitHub Secrets (add these to your GitHub repository):" -ForegroundColor Yellow
    Write-Host "  AZURE_CREDENTIALS:" -ForegroundColor Cyan
    $ServicePrincipal | ConvertTo-Json -Depth 10
    Write-Host ""
    Write-Host "  DOCKER_USERNAME: $RegistryUsername" -ForegroundColor Cyan
    Write-Host "  DOCKER_PASSWORD: [Check Azure Portal or use registry password above]" -ForegroundColor Cyan
    Write-Host "  SECRET_KEY_BASE: $SecretKeyBase" -ForegroundColor Cyan
    Write-Host ""
} catch {
    Write-Host "❌ Failed to create service principal. Error: $_" -ForegroundColor Red
}

# Summary
Write-Host "🎉 Azure Deployment Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Add the GitHub Secrets shown above to your repository"
Write-Host "2. Push your code to the main branch to trigger deployment"
Write-Host "3. Monitor the GitHub Actions workflow"
Write-Host ""
Write-Host "🌐 Your application will be available at:" -ForegroundColor Green
Write-Host "   Frontend: https://$WebAppName.azurewebsites.net"
Write-Host "   Admin: https://$WebAppName.azurewebsites.net/admin"
Write-Host ""
Write-Host "🔐 Admin Credentials:" -ForegroundColor Yellow
Write-Host "   Email: admin@golfnvibes.com"
Write-Host "   Password: GolfNVibes2024!"
Write-Host ""
Write-Host "💡 To monitor deployment:" -ForegroundColor Cyan
Write-Host "   az webapp log tail --name $WebAppName --resource-group $ResourceGroup"