#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Content & Config Setup${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "server/seed-content.js" ]; then
    echo -e "${RED}Error: server/seed-content.js not found!${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Navigate to server directory
cd server

echo -e "${YELLOW}📦 Installing dependencies...${NC}"
npm install

echo ""
echo -e "${YELLOW}🌱 Seeding content and configurations...${NC}"
node seed-content.js

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Setup completed successfully!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Restart backend: docker compose restart socket-server"
    echo "2. Access admin dashboard: https://adminular.ueu-fasilkom.my.id"
    echo "3. Rebuild Flutter app: flutter build apk --release"
    echo ""
    echo -e "${BLUE}Test endpoints:${NC}"
    echo "curl https://apiular.ueu-fasilkom.my.id/api/content/snake_message"
    echo "curl https://apiular.ueu-fasilkom.my.id/api/config/public"
else
    echo ""
    echo -e "${RED}❌ Setup failed!${NC}"
    echo "Please check the error messages above"
    exit 1
fi
