#!/bin/bash
# ============================================================
# APEX — Cleanup Script
# Deletes ALL Azure resources created for the APEX project
# ============================================================
# WARNING: This will permanently delete all resources!
# ============================================================

set -e

RESOURCE_GROUP="rg-apex-project"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}============================================${NC}"
echo -e "${RED}  APEX — Resource Cleanup${NC}"
echo -e "${RED}============================================${NC}"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will permanently delete all resources in:${NC}"
echo -e "${YELLOW}   Resource Group: $RESOURCE_GROUP${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" = "yes" ]; then
  echo -e "${YELLOW}Deleting resource group and all resources...${NC}"
  az group delete \
    --name $RESOURCE_GROUP \
    --yes \
    --no-wait
  echo -e "${GREEN}✅ Resource group deletion initiated (may take a few minutes)${NC}"
else
  echo -e "${GREEN}Cleanup cancelled.${NC}"
fi
