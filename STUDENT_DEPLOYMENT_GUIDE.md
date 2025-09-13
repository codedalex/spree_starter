# 🎓 Student-Friendly Deployment Guide for Golf N Vibes

Since Azure App Service is currently throttled on your student account, here are the best FREE/cheap alternatives:

## 🚀 Option 1: Railway (Recommended)

**Why Railway?**
- ✅ $5/month credit (covers small apps)
- ✅ PostgreSQL included free
- ✅ Automatic deployments from GitHub
- ✅ Student-friendly pricing

**Setup Steps:**
1. Go to [railway.app](https://railway.app)
2. Sign up with your GitHub account
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your `spree_starter` repository
5. Railway will automatically detect the Dockerfile and deploy

**Environment Variables to Set in Railway:**
```
RAILS_ENV=production
SECRET_KEY_BASE=your-secret-key-here
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SPREE_ADMIN_EMAIL=admin@golfnvibes.com
SPREE_ADMIN_PASSWORD=GolfNVibes2024!
STORE_NAME=Golf N Vibes
STORE_EMAIL=info@golfnvibes.com
```

Railway will automatically provide a PostgreSQL database with connection details.

## 🚀 Option 2: Render (Free Tier)

**Why Render?**
- ✅ Completely free tier
- ✅ PostgreSQL addon available
- ✅ Docker support
- ✅ Auto-deploy from GitHub

**Setup Steps:**
1. Go to [render.com](https://render.com)
2. Sign up with GitHub
3. Create "New Web Service"
4. Connect your repository
5. Set environment to "Docker"
6. Add PostgreSQL database from add-ons

## 🚀 Option 3: Heroku Alternative - Fly.io

**Why Fly.io?**
- ✅ Good free allowance
- ✅ PostgreSQL support
- ✅ Docker-native
- ✅ Global edge locations

## 🔧 Current Azure Resources (Keep These)

You already have:
- ✅ **Container Registry**: `golfvibesacr2025.azurecr.io` (can be used later)
- ✅ **PostgreSQL Database**: `golf-n-vibes-postgres.postgres.database.azure.com`
- ✅ **Resource Group**: `golf-n-vibes-rg`

## 💡 Recommended Approach

1. **Start with Railway** - deploy your app immediately
2. **Test everything works** - verify your fixes
3. **Later migrate to Azure** - when throttling clears (usually 24-48 hours)

## 🐳 Docker Hub Alternative

If you want to stick with Azure but use Docker Hub:

1. Create account at [hub.docker.com](https://hub.docker.com)
2. Create repository: `yourusername/golf-n-vibes-spree`
3. Update GitHub secrets:
   - `DOCKER_USERNAME`: your Docker Hub username
   - `DOCKER_PASSWORD`: your Docker Hub password

The workflow is already configured to use Docker Hub as a fallback!

## 🎯 Next Steps

Choose one of the above options and let me know - I can help you set it up step by step!