# GitHub Setup for Golf N Vibes Spree Deployment

This guide walks you through setting up GitHub repository secrets and configuring the deployment pipeline for your Golf N Vibes Spree store.

## Prerequisites

1. **GitHub Repository**: Your Spree application code pushed to GitHub
2. **Azure Resources**: Created as per `deploy-to-azure.md`
3. **Azure CLI**: Installed and authenticated
4. **Admin Access**: To your GitHub repository

## Step 1: Create Azure Service Principal

The GitHub Actions workflow needs permissions to deploy to Azure. We'll create a service principal with contributor access.

### Get Your Subscription ID
```bash
az account show --query id --output tsv
```

### Create Service Principal
```bash
az ad sp create-for-rbac \
  --name "golf-n-vibes-github-actions" \
  --role contributor \
  --scopes /subscriptions/{your-subscription-id}/resourceGroups/golf-n-vibes-rg \
  --sdk-auth
```

**Important**: Save the entire JSON output - you'll need it for the `AZURE_CREDENTIALS` secret.

Example output:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Step 2: Get Azure Container Registry Credentials

### Get ACR Login Server
```bash
az acr show --name golfnvibesacr --resource-group golf-n-vibes-rg --query loginServer --output tsv
```

### Get ACR Credentials
```bash
az acr credential show --name golfnvibesacr --resource-group golf-n-vibes-rg
```

Example output:
```json
{
  "passwords": [
    {
      "name": "password",
      "value": "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    },
    {
      "name": "password2", 
      "value": "xxxxxxxxxxxxxxxxxxxxxxxxxx"
    }
  ],
  "username": "golfnvibesacr"
}
```

## Step 3: Generate Rails Secret Key

Generate a secret key for your Rails application:

```bash
# If you have Rails installed locally
rails secret

# Or using Ruby directly
ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"

# Or online generator (not recommended for production)
# Use: https://api.rubyonrails.org/classes/SecureRandom.html
```

## Step 4: Configure GitHub Repository Secrets

Navigate to your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret** for each of the following:

### Required Secrets

#### `AZURE_CREDENTIALS`
- **Value**: The complete JSON output from Step 1 (service principal creation)
- **Description**: Azure service principal credentials for deployment

#### `REGISTRY_LOGIN_SERVER`
- **Value**: `golfnvibesacr.azurecr.io` (from Step 2)
- **Description**: Azure Container Registry login server URL

#### `REGISTRY_USERNAME`
- **Value**: `golfnvibesacr` (from Step 2)
- **Description**: Azure Container Registry username

#### `REGISTRY_PASSWORD`
- **Value**: One of the password values from Step 2
- **Description**: Azure Container Registry password

#### `SECRET_KEY_BASE`
- **Value**: The secret key generated in Step 3
- **Description**: Rails application secret key for sessions and encryption

### Optional Secrets (for production features)

#### Payment Gateway Secrets
If you plan to use Stripe:
- `STRIPE_PUBLISHABLE_KEY`: Your Stripe publishable key
- `STRIPE_SECRET_KEY`: Your Stripe secret key

If you plan to use PayPal:
- `PAYPAL_CLIENT_ID`: Your PayPal client ID
- `PAYPAL_CLIENT_SECRET`: Your PayPal client secret

#### Email Service Secrets
For SendGrid:
- `SENDGRID_API_KEY`: Your SendGrid API key

For other email providers:
- `SMTP_PASSWORD`: Your SMTP password

#### Analytics and Monitoring
- `GA_TRACKING_ID`: Google Analytics tracking ID
- `SENTRY_DSN`: Sentry error tracking DSN

## Step 5: Configure Repository Settings

### Branch Protection (Optional but Recommended)
1. Go to **Settings** → **Branches**
2. Add rule for `main` branch
3. Enable:
   - Require status checks to pass before merging
   - Require up-to-date branches before merging
   - Include administrators

### Environment Protection (Optional)
1. Go to **Settings** → **Environments**
2. Create `production` environment
3. Add protection rules:
   - Required reviewers
   - Wait timer
   - Branch restrictions

## Step 6: Test the Setup

### Trigger Manual Deployment
1. Go to **Actions** tab in your repository
2. Find the "Deploy to Azure Web App" workflow
3. Click **Run workflow** → **Run workflow**

### Verify Workflow
The workflow should:
1. ✅ Checkout code
2. ✅ Set up Ruby and install dependencies
3. ✅ Precompile assets
4. ✅ Build and push Docker image
5. ✅ Deploy to Azure Web App
6. ✅ Run database migrations

### Check Deployment
Visit your application:
- **Store**: `https://golf-n-vibes-spree.azurewebsites.net`
- **Admin**: `https://golf-n-vibes-spree.azurewebsites.net/admin`

## Troubleshooting

### Common Issues

#### 1. Authentication Failures
```
Error: The provided credentials are invalid
```
**Solution**: 
- Verify `AZURE_CREDENTIALS` is the complete JSON from service principal creation
- Ensure service principal has contributor role on resource group

#### 2. Container Registry Access Denied
```
Error: unauthorized: authentication required
```
**Solution**:
- Verify `REGISTRY_LOGIN_SERVER`, `REGISTRY_USERNAME`, `REGISTRY_PASSWORD` are correct
- Ensure ACR admin user is enabled: `az acr update --name golfnvibesacr --admin-enabled true`

#### 3. Secret Key Issues
```
Error: Rails application failed to start - invalid secret key
```
**Solution**:
- Verify `SECRET_KEY_BASE` is a valid 128-character hex string
- Generate new key: `rails secret` or `ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"`

#### 4. Asset Precompilation Failures
```
Error: Asset precompilation failed
```
**Solution**:
- Ensure all required environment variables are set
- Check for missing gems or Node.js dependencies

### Getting Help

#### View Workflow Logs
1. Go to **Actions** tab
2. Click on failed workflow run
3. Expand failed step to see detailed logs

#### Azure Resource Logs
```bash
# Web App logs
az webapp log tail --name golf-n-vibes-spree --resource-group golf-n-vibes-rg

# Container instance logs
az webapp log show --name golf-n-vibes-spree --resource-group golf-n-vibes-rg
```

#### Debug Container Registry
```bash
# Test login
az acr login --name golfnvibesacr

# List repositories
az acr repository list --name golfnvibesacr

# Show image tags
az acr repository show-tags --name golfnvibesacr --repository spree-golf
```

## Security Best Practices

1. **Rotate Secrets Regularly**: Update service principal credentials and container registry passwords periodically
2. **Limit Permissions**: Service principal should have minimal required permissions
3. **Monitor Access**: Review deployment logs and access patterns
4. **Environment Separation**: Use different secrets for staging vs production
5. **Secret Management**: Consider using Azure Key Vault for production secrets

## Next Steps

After successful setup:
1. **Configure Production Environment Variables** in Azure Web App
2. **Set Up Custom Domain** (optional)
3. **Configure SSL Certificate** (Azure provides free SSL for .azurewebsites.net)
4. **Set Up Monitoring** with Azure Application Insights
5. **Configure Backups** for your application data

Your Golf N Vibes Spree store is now ready for continuous deployment! 🏌️‍♂️
