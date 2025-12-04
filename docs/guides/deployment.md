# Deployment Guide

## Prerequisites

- [Render.com](https://render.com) account
- Git repository (GitHub, GitLab, or Bitbucket)
- `config/master.key` file (never commit to version control)

## Quick Start (Blueprint)

1. Push code to Git repository
2. Go to [Render Dashboard](https://dashboard.render.com/)
3. Click "New +" → "Blueprint"
4. Connect your repository
5. Set `RAILS_MASTER_KEY` environment variable (contents of `config/master.key`)
6. Click "Apply"

The `render.yaml` file defines all infrastructure automatically.

## Manual Setup

### 1. Create PostgreSQL Database

- Click "New +" → "PostgreSQL"
- Name: `task-tracker-db`
- Plan: Free
- Save the "Internal Database URL"

### 2. Create Web Service

- Click "New +" → "Web Service"
- Connect repository
- Build Command: `./bin/render-build.sh`
- Start Command: `bin/rails server`
- Plan: Free

### 3. Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `DATABASE_URL` | [Internal Database URL from Step 1] | PostgreSQL connection string |
| `RAILS_MASTER_KEY` | [Contents of config/master.key] | Rails credentials encryption key |
| `RAILS_ENV` | `production` | Rails environment |
| `WEB_CONCURRENCY` | `2` | Number of Puma workers (prevents memory issues on free tier) |

## Deployment Files

- **`bin/render-build.sh`**: Build script (bundle, assets, migrations)
- **`render.yaml`**: Infrastructure-as-code Blueprint
- **`config/database.yml`**: Production uses `DATABASE_URL` env var

## Free Tier Limitations

- Services spin down after 15 minutes of inactivity
- Cold start: 30+ seconds for first request
- Database: 90 days retention limit
- 750 hours/month usage

## Security

- **Never** commit `config/master.key`
- Store `RAILS_MASTER_KEY` in Render environment variables only
- All secrets via environment variables

## Troubleshooting

**Assets fail to compile**:
- Test locally: `bin/rails assets:precompile`

**Database connection issues**:
- Verify `DATABASE_URL` is set correctly
- Ensure database created before web service

**Application won't start**:
- Check `RAILS_MASTER_KEY` matches local `config/master.key`
- Review build logs for migration errors

## Updates

Push to Git → Render auto-deploys → Migrations run automatically

## Resources

- [Render Rails 8 Guide](https://render.com/docs/deploy-rails-8)
- [Render PostgreSQL Docs](https://render.com/docs/databases)
