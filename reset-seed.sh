#!/bin/bash

# Reset and Reseed Database Script
# This script resets the database and seeds all data from scratch
#
# Usage: ./reset-seed.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️  Database Reset & Reseed${NC}"
echo "===================================="
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will DELETE all data!${NC}"
echo ""
echo "This includes:"
echo "  - All users (except those recreated by seed)"
echo "  - All game histories"
echo "  - All quizzes"
echo "  - All board configurations"
echo "  - All content"
echo "  - All app configurations"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Operation cancelled"
    exit 0
fi

echo ""
echo -e "${GREEN}Starting reset and reseed process...${NC}"
echo ""

# Step 1: Reset database
echo -e "${RED}Step 1: Resetting database...${NC}"
if docker compose exec -T socket-server node reset-database.js; then
    echo "✅ Database reset complete"
else
    echo "❌ Failed to reset database"
    exit 1
fi
echo ""

# Step 2: Seed base data (users, quizzes, board configs)
echo -e "${GREEN}Step 2: Seeding base data...${NC}"
if docker compose exec -T socket-server node seed.js; then
    echo "✅ Base data seeded"
else
    echo "❌ Failed to seed base data"
    exit 1
fi
echo ""

# Step 3: Seed content and app configs
echo -e "${GREEN}Step 3: Seeding educational content...${NC}"
if docker compose exec -T socket-server node seed-content.js; then
    echo "✅ Educational content seeded"
else
    echo "❌ Failed to seed content"
    exit 1
fi
echo ""

# Step 4: Seed environment configurations
echo -e "${GREEN}Step 4: Seeding environment configurations...${NC}"
if docker compose exec -T socket-server node seed-environment.js; then
    echo "✅ Environment configurations seeded"
else
    echo "❌ Failed to seed environment configurations"
    exit 1
fi
echo ""

# Summary
echo "================================================"
echo -e "${GREEN}✅ Reset and reseed completed successfully!${NC}"
echo "================================================"
echo ""
echo "📊 Data seeded:"
echo "   ✅ Admin user and test users"
echo "   ✅ Quiz questions (30+)"
echo "   ✅ Board configurations"
echo "   ✅ Educational content (40 items)"
echo "   ✅ App configurations (14 items)"
echo "   ✅ Environment configurations (12 items)"
echo ""
echo "🔑 Default Admin Credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "🌐 Services:"
echo "   Backend:  http://localhost:3000"
echo "   Admin:    http://localhost:8080"
echo ""
