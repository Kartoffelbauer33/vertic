#!/bin/bash
# Serverpod Deployment Script
set -e

echo "🚀 Starting Serverpod deployment..."

# Git pull latest changes
echo "📦 Pulling latest code..."
git pull origin main

# Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Build new containers
echo "🔨 Building new containers..."
docker-compose build --no-cache

# Start containers
echo "▶️ Starting containers..."
docker-compose up -d

# Wait for server to be ready
echo "⏳ Waiting for server to start..."
sleep 10

# Health check
echo "🔍 Health check..."
curl -f http://localhost:8080/health || echo "Server not ready yet"

echo "✅ Deployment complete!"
echo "🌐 Server: http://159.69.144.208:8080" 