# Deploy Golf N Vibes Spree Store to Azure

This guide walks you through deploying the Golf N Vibes Spree e-commerce store to Microsoft Azure using free tier resources.

## Prerequisites

1. **Azure Student Subscription** - Free Azure resources with regional restrictions
2. **GitHub Account** - For source code and CI/CD pipeline
3. **Azure CLI** - For resource management
4. **Git** - For version control

## Azure Resources Required (Free Tier)

Due to Azure Student subscription restrictions, all resources must be created in supported regions:
- Austria East
- Switzerland North
- UAE North
- South Africa North
- Italy North

### Resources Created:
1. **Resource Group**: `golf-n-vibes-rg`
2. **App Service Plan**: Linux Basic B1 (free tier)
3. **Web App**: `golf-n-vibes-spree`
4. **Container Registry**: `golfnvibesacr` (Basic tier)
5. **Database**: SQLite (embedded, zero-cost)

## Step-by-Step Deployment

### 1. Create Azure Resources

#### Resource Group
```bash
az group create --name golf-n-vibes-rg --location "Switzerland North"
```

#### Container Registry
```bash
az acr create --resource-group golf-n-vibes-rg --name golfnvibesacr --sku Basic --location "Switzerland North"
```

#### App Service Plan
```bash
az appservice plan create --name golf-n-vibes-plan --resource-group golf-n-vibes-rg --location "Switzerland North" --sku B1 --is-linux
```

#### Web App
```bash
az webapp create --resource-group golf-n-vibes-rg --plan golf-n-vibes-plan --name golf-n-vibes-spree --deployment-container-image-name golfnvibesacr.azurecr.io/spree-golf:latest
```

### 2. Configure Container Registry

#### Enable Admin User
```bash
az acr update --name golfnvibesacr --admin-enabled true
```

#### Get Registry Credentials
```bash
az acr credential show --name golfnvibesacr --resource-group golf-n-vibes-rg
```

### 3. Set Up GitHub Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

#### Azure Credentials
```bash
# Get Azure Service Principal credentials
az ad sp create-for-rbac --name "golf-n-vibes-github" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/golf-n-vibes-rg --sdk-auth
```

- `AZURE_CREDENTIALS`: The full JSON output from the command above

#### Container Registry
- `REGISTRY_LOGIN_SERVER`: `golfnvibesacr.azurecr.io`
- `REGISTRY_USERNAME`: From `az acr credential show` command
- `REGISTRY_PASSWORD`: From `az acr credential show` command

#### Application Secrets
- `SECRET_KEY_BASE`: Generate with `rails secret`

### 4. Configure Web App Environment

#### Set Container Registry
```bash
az webapp config container set --name golf-n-vibes-spree --resource-group golf-n-vibes-rg --docker-custom-image-name golfnvibesacr.azurecr.io/spree-golf:latest --docker-registry-server-url https://golfnvibesacr.azurecr.io --docker-registry-server-user [username] --docker-registry-server-password [password]
```

#### Configure Environment Variables
```bash
az webapp config appsettings set --resource-group golf-n-vibes-rg --name golf-n-vibes-spree --settings \
  RAILS_ENV=production \
  SECRET_KEY_BASE="your_secret_key_base" \
  RAILS_SERVE_STATIC_FILES=true \
  RAILS_LOG_TO_STDOUT=true \
  FORCE_SSL=false \
  SPREE_ADMIN_EMAIL=admin@golfnvibes.com \
  SPREE_ADMIN_PASSWORD=secure_password \
  STORE_NAME="Golf N Vibes" \
  STORE_EMAIL=info@golfnvibes.com
```

### 5. Deploy Using GitHub Actions

1. Push code to the `main` branch
2. GitHub Actions will automatically:
   - Build the Docker image
   - Push to Azure Container Registry
   - Deploy to Azure Web App
   - Run database migrations
   - Load sample data (first deployment)

### 6. Post-Deployment Tasks

#### Access Your Store
- **Frontend**: `https://golf-n-vibes-spree.azurewebsites.net`
- **Admin Panel**: `https://golf-n-vibes-spree.azurewebsites.net/admin`

#### Initial Setup
1. Log into admin panel with credentials from environment variables
2. Configure store settings (name, email, etc.)
3. Set up payment methods (Stripe, PayPal)
4. Add your product catalog
5. Configure shipping methods and zones

### 7. Monitor and Maintain

#### View Logs
```bash
az webapp log tail --name golf-n-vibes-spree --resource-group golf-n-vibes-rg
```

#### Access Container
```bash
az webapp ssh --resource-group golf-n-vibes-rg --name golf-n-vibes-spree
```

#### Database Management
Since we're using SQLite, the database is stored in the container. For persistent data:

1. **Backup**: Export data regularly
```bash
# In container
cd /app && bundle exec rails db:seed:dump
```

2. **Migrations**: Run automatically via GitHub Actions or manually:
```bash
az webapp ssh --resource-group golf-n-vibes-rg --name golf-n-vibes-spree --instance 0 "cd /app && bundle exec rails db:migrate"
```

## Troubleshooting

### Common Issues

1. **Container fails to start**
   - Check logs: `az webapp log tail --name golf-n-vibes-spree --resource-group golf-n-vibes-rg`
   - Verify environment variables are set correctly

2. **Database issues**
   - SQLite database is ephemeral in containers
   - For production, consider upgrading to Azure Database for PostgreSQL when budget allows

3. **Asset loading issues**
   - Ensure `RAILS_SERVE_STATIC_FILES=true` is set
   - Check asset precompilation in build logs

4. **SSL certificate issues**
   - Azure provides free SSL for *.azurewebsites.net domains
   - For custom domains, configure SSL in Azure Portal

### Cost Management

This setup uses only free tier resources:
- **Basic App Service Plan**: Free tier (B1 has minimal cost)
- **Basic Container Registry**: Free tier
- **SQLite Database**: No additional cost
- **Storage**: Uses local container storage

Total estimated cost: ~$0-15/month depending on traffic

## Scaling Considerations

For production traffic, consider:
1. Upgrade to Premium App Service Plan for better performance
2. Implement Azure Database for PostgreSQL
3. Add Azure Cache for Redis for session management
4. Configure Azure CDN for static assets
5. Set up Azure Application Insights for monitoring

## Security Best Practices

1. **Environment Variables**: Never commit secrets to git
2. **HTTPS**: Always use SSL in production
3. **Admin Access**: Use strong passwords and consider 2FA
4. **Updates**: Keep dependencies updated
5. **Monitoring**: Set up alerts for errors and performance

This completes the Azure deployment setup for your Golf N Vibes Spree store!
