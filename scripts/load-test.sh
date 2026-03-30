#!/bin/bash
# ============================================================
# APEX — Load Test Script
# Simulates traffic to trigger auto-scaling
# ============================================================
# Uses Apache Bench (ab) to send concurrent requests
# Monitor Azure Portal → App Service Plan → Scale Out
# while this runs to see auto-scaling in action
# ============================================================

WEB_APP_URL="https://kaviarasan-portfolio-apex.azurewebsites.net/"
TOTAL_REQUESTS=10000
CONCURRENT_USERS=100

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  APEX — Load Test (Auto-Scale Demo)${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}Target:      $WEB_APP_URL${NC}"
echo -e "${YELLOW}Requests:    $TOTAL_REQUESTS${NC}"
echo -e "${YELLOW}Concurrency: $CONCURRENT_USERS${NC}"
echo ""
echo -e "${GREEN}📊 Open Azure Portal → App Service Plan → Scale Out${NC}"
echo -e "${GREEN}   to watch instances scale up during this test!${NC}"
echo ""
echo -e "${YELLOW}Starting load test in 5 seconds...${NC}"
sleep 5

# Run Apache Bench
ab -n $TOTAL_REQUESTS -c $CONCURRENT_USERS $WEB_APP_URL

echo ""
echo -e "${GREEN}✅ Load test complete!${NC}"
echo -e "${YELLOW}Check Azure Portal for auto-scale events.${NC}"
echo -e "${YELLOW}It may take 5-10 minutes for scaling to initiate.${NC}"
