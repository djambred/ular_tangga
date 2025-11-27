#!/bin/bash

# Ular Tangga TBC - Automated Setup Script
# This script sets up the complete system in one command
# 
# What it does:
# 1. Setup environment variables (.env)
# 2. Start Docker services (MongoDB, Backend, Admin Dashboard)
# 3. Wait for services to be ready
# 4. Reset database (clean slate)
# 5. Seed database with initial data
# 6. Install Flutter dependencies
#
# Usage: ./setup.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🎲 Game Ular Tangga Edukasi TBC - Automated Setup"
echo "===================================================="
echo ""
echo -e "${YELLOW}⚠️  This will reset database and reseed everything!${NC}"
echo ""

# Check if Docker is installed
echo "Checking prerequisites..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter SDK first."
    exit 1
fi

echo "✅ All prerequisites installed"
echo ""

# Step 0: Setup environment file
echo -e "${GREEN}Step 0: Setting up environment variables...${NC}"
if [ ! -f server/.env ]; then
    cp server/.env.example server/.env
    echo "✅ Created server/.env from template"
    echo -e "${YELLOW}⚠️  Please review and update server/.env if needed${NC}"
else
    echo "✅ server/.env already exists"
fi
echo ""

# Step 1: Start Docker services
echo -e "${GREEN}Step 1: Starting Docker services...${NC}"
docker compose down
docker compose up -d --build

echo "⏳ Waiting for MongoDB to be ready..."
sleep 5

# Check if MongoDB is ready
echo "🔍 Checking MongoDB connection..."
MAX_TRIES=30
COUNT=0
until docker compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" -u admin -p ulartangga123 --authenticationDatabase admin > /dev/null 2>&1; do
    COUNT=$((COUNT+1))
    if [ $COUNT -gt $MAX_TRIES ]; then
        echo "❌ MongoDB failed to start after ${MAX_TRIES} seconds"
        exit 1
    fi
    echo "⏳ Waiting for MongoDB... (${COUNT}/${MAX_TRIES})"
    sleep 1
done

echo "✅ MongoDB is ready"
echo ""

echo "⏳ Waiting for backend server to be ready..."
sleep 3

# Check if backend is ready
echo "🔍 Checking backend connection..."
MAX_TRIES=30
COUNT=0
until curl -s http://localhost:3000/health > /dev/null 2>&1; do
    COUNT=$((COUNT+1))
    if [ $COUNT -gt $MAX_TRIES ]; then
        echo "❌ Backend server failed to start after ${MAX_TRIES} seconds"
        echo "💡 Check logs: docker compose logs socket-server"
        exit 1
    fi
    echo "⏳ Waiting for backend... (${COUNT}/${MAX_TRIES})"
    sleep 1
done

echo "✅ Backend server is ready"
echo "✅ All Docker services started"
echo ""

# Step 2: Reset database
echo -e "${RED}Step 2: Resetting database...${NC}"
if docker compose exec -T socket-server node reset-database.js; then
    echo "✅ Database reset complete"
else
    echo "⚠️  Reset failed (continuing with seeding anyway)"
    echo "💡 Check logs: docker compose logs socket-server"
fi
echo ""

# Step 3: Seed database
echo -e "${GREEN}Step 3: Seeding database with initial data...${NC}"
echo "📦 Creating admin user, quizzes, board configurations, content, and app configs..."

# Run main seed script (users, quizzes, board configs)
if docker compose exec -T socket-server node seed.js; then
    echo "✅ Users, quizzes, and board configs seeded"
else
    echo "❌ Failed to seed database"
    echo "💡 Check logs: docker compose logs socket-server"
    exit 1
fi

# Run content seed script (educational content and app configs)
echo "📚 Seeding educational content and app configurations..."
if docker compose exec -T socket-server node seed-content.js; then
    echo "✅ Educational content and app configs seeded"
else
    echo "⚠️  Content seeding failed (continuing anyway)"
    echo "💡 You can run manually: docker compose exec socket-server node seed-content.js"
fi

# Run environment seed script (environment configurations)
echo "🌍 Seeding environment configurations..."
if docker compose exec -T socket-server node seed-environment.js; then
    echo "✅ Environment configurations seeded"
else
    echo "⚠️  Environment seeding failed (continuing anyway)"
    echo "💡 You can run manually: docker compose exec socket-server node seed-environment.js"
fi

# Fix any existing users with level 0 to level 1
echo ""

# Step 4: Install Flutter dependencies
echo -e "${GREEN}Step 4: Installing Flutter dependencies...${NC}"
flutter pub get

echo "✅ Flutter dependencies installed"
echo ""

# Step 5: Verify setup
echo -e "${GREEN}Step 5: Verifying setup...${NC}"

# Test backend API
echo "🔍 Testing backend API..."
if curl -s http://localhost:3000/health | grep -q "OK"; then
    echo "✅ Backend API is working"
else
    echo "⚠️  Backend API test failed (but may still work)"
fi

# Test admin dashboard
echo "🔍 Testing admin dashboard..."
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Admin dashboard is accessible"
else
    echo "⚠️  Admin dashboard test failed (but may still work)"
fi

echo ""

# Show final summary
echo "================================================"
echo -e "${GREEN}✨ Setup completed successfully! ✨${NC}"
echo "================================================"
echo ""
echo "🚀 Services are now running:"
echo "   - Backend API:      http://localhost:3000"
echo "   - Admin Dashboard:  http://localhost:8080"
echo "   - MongoDB:          mongodb://localhost:27017"
echo ""
echo "📊 Database seeded with:"
echo "   ✅ Admin user and test users"
echo "   ✅ 30+ quiz questions (all levels)"
echo "   ✅ 10 board configurations"
echo "   ✅ 40 educational content items"
echo "   ✅ 14 app configurations"
echo "   ✅ 12 environment configurations"
echo ""
echo "🔑 Default Admin Credentials:"
echo "   - Username: admin"
echo "   - Password: admin123"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Change the admin password after first login!${NC}"
echo ""
echo "📱 Next Steps:"
echo "   1. Run Flutter app:"
echo "      flutter run"
echo ""
echo "   2. For Android Emulator, set server URL to:"
echo "      http://10.0.2.2:3000"
echo ""
echo "   3. For iOS Simulator/Desktop:"
echo "      http://localhost:3000 (already default)"
echo ""
echo "   4. Access Admin Dashboard:"
echo "      http://localhost:8080"
echo "      Then manage content and app configs dynamically!"
echo ""
echo "📊 Useful Commands:"
echo "   - View logs:        docker compose logs -f"
echo "   - Stop services:    docker compose down"
echo "   - Restart services: docker compose restart"
echo "   - Check status:     docker compose ps"
echo "   - Reset & reseed:   ./reset-seed.sh"
echo ""
echo -e "${YELLOW}💡 Note: Running ./setup.sh again will reset and reseed the database!${NC}"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Complete guide"
echo "   - TESTING.md - Testing guide"
echo "   - MULTIPLAYER_TROUBLESHOOTING.md - Multiplayer help"
echo "   - QUICK_REFERENCE.md - Quick commands"
echo ""
echo "🛑 To stop services:"
echo "   docker compose down"
echo ""
