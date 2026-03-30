#!/bin/bash
# ============================================================
# APEX — Automated Pipeline for Elastic eXecution
# Phase 1: Azure Infrastructure Setup Script
# ============================================================
# This script creates all required Azure resources for the
# APEX project. Run this after logging in with 'az login'.
# ============================================================

set -e  # Exit on error

# ==========================================
# CONFIGURATION — Modify these values
# ==========================================
RESOURCE_GROUP="rg-apex-project"
LOCATION="centralindia"
APP_SERVICE_PLAN="asp-apex-portfolio"
WEB_APP_NAME="kaviarasan-portfolio-apex"
APP_INSIGHTS_NAME="appi-apex-portfolio"
KEY_VAULT_NAME="kv-apex-portfolio"
LOG_ANALYTICS_WORKSPACE="law-apex-portfolio"
ACTION_GROUP_NAME="ag-apex-team"
ALERT_EMAIL="cb.sc.p2cse25017@cb.students.amrita.edu"  # <-- CHANGE THIS TO YOUR EMAIL

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  APEX — Azure Infrastructure Setup${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==========================================
# PHASE 1: Resource Group
# ==========================================
echo -e "${YELLOW}[Phase 1/6] Creating Resource Group...${NC}"
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --output table
echo -e "${GREEN}✅ Resource Group created: $RESOURCE_GROUP${NC}"
echo ""

# ==========================================
# PHASE 1: App Service Plan (Standard S1)
# ==========================================
echo -e "${YELLOW}[Phase 1/6] Creating App Service Plan (Standard S1 - Linux)...${NC}"
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --sku S1 \
  --is-linux \
  --output table
echo -e "${GREEN}✅ App Service Plan created: $APP_SERVICE_PLAN (S1, Linux)${NC}"
echo ""

# ==========================================
# PHASE 1: Web App
# ==========================================
echo -e "${YELLOW}[Phase 1/6] Creating Web App (Node.js 20 LTS)...${NC}"
az webapp create \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --runtime "NODE:20-lts" \
  --output table
echo -e "${GREEN}✅ Web App created: https://${WEB_APP_NAME}.azurewebsites.net${NC}"
echo ""

# Configure App Settings
echo -e "${YELLOW}[Phase 1/6] Configuring App Settings...${NC}"
az webapp config appsettings set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings WEBSITE_NODE_DEFAULT_VERSION="~20" SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
  --output table
echo -e "${GREEN}✅ App Settings configured${NC}"
echo ""

# ==========================================
# PHASE 3: Auto Scaling
# ==========================================
echo -e "${YELLOW}[Phase 3/6] Configuring Auto Scaling...${NC}"

# Get the App Service Plan resource ID
ASP_RESOURCE_ID=$(az appservice plan show \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --query id --output tsv)

# Create auto-scale settings
az monitor autoscale create \
  --resource $ASP_RESOURCE_ID \
  --name autoscale-apex \
  --min-count 1 \
  --max-count 5 \
  --count 1 \
  --output table

# Scale OUT: CPU > 70% for 5 minutes
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-apex \
  --condition "CpuPercentage > 70 avg 5m" \
  --scale out 1 \
  --output table

# Scale IN: CPU < 30% for 5 minutes
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-apex \
  --condition "CpuPercentage < 30 avg 5m" \
  --scale in 1 \
  --output table

# Scale OUT: Memory > 80%
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-apex \
  --condition "MemoryPercentage > 80 avg 5m" \
  --scale out 1 \
  --output table

# Scale IN: Memory < 40%
az monitor autoscale rule create \
  --resource-group $RESOURCE_GROUP \
  --autoscale-name autoscale-apex \
  --condition "MemoryPercentage < 40 avg 5m" \
  --scale in 1 \
  --output table

echo -e "${GREEN}✅ Auto Scaling configured (Min: 1, Max: 5 instances)${NC}"
echo ""

# ==========================================
# PHASE 4: Application Insights
# ==========================================
echo -e "${YELLOW}[Phase 4/6] Creating Application Insights...${NC}"
az monitor app-insights component create \
  --app $APP_INSIGHTS_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web \
  --output table

# Get instrumentation key and connection string
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey --output tsv)

CONNECTION_STRING=$(az monitor app-insights component show \
  --app $APP_INSIGHTS_NAME \
  --resource-group $RESOURCE_GROUP \
  --query connectionString --output tsv)

# Link to Web App
az webapp config appsettings set \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="$INSTRUMENTATION_KEY" \
             APPLICATIONINSIGHTS_CONNECTION_STRING="$CONNECTION_STRING" \
  --output table

echo -e "${GREEN}✅ Application Insights linked to Web App${NC}"
echo ""

# ==========================================
# PHASE 4: Log Analytics Workspace
# ==========================================
echo -e "${YELLOW}[Phase 4/6] Creating Log Analytics Workspace...${NC}"
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_WORKSPACE \
  --location $LOCATION \
  --output table
echo -e "${GREEN}✅ Log Analytics Workspace created${NC}"
echo ""

# ==========================================
# PHASE 4: Alert Rules
# ==========================================
echo -e "${YELLOW}[Phase 4/6] Creating Action Group & Alert Rules...${NC}"

# Create action group for email notifications
az monitor action-group create \
  --name $ACTION_GROUP_NAME \
  --resource-group $RESOURCE_GROUP \
  --short-name "APEXAlerts" \
  --action email apex-admin $ALERT_EMAIL \
  --output table

# Get Web App resource ID for alerts
WEBAPP_RESOURCE_ID=$(az webapp show \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id --output tsv)

ACTION_GROUP_ID=$(az monitor action-group show \
  --name $ACTION_GROUP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id --output tsv)

# Alert: High CPU
az monitor metrics alert create \
  --name "alert-high-cpu" \
  --resource-group $RESOURCE_GROUP \
  --scopes $WEBAPP_RESOURCE_ID \
  --condition "avg CpuPercentage > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action $ACTION_GROUP_ID \
  --description "CPU usage exceeds 80% for 5 minutes" \
  --output table

# Alert: Slow Response Time
az monitor metrics alert create \
  --name "alert-slow-response" \
  --resource-group $RESOURCE_GROUP \
  --scopes $WEBAPP_RESOURCE_ID \
  --condition "avg HttpResponseTime > 5" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action $ACTION_GROUP_ID \
  --description "Average response time exceeds 5 seconds" \
  --output table

# Alert: Server Errors (HTTP 5xx)
az monitor metrics alert create \
  --name "alert-server-errors" \
  --resource-group $RESOURCE_GROUP \
  --scopes $WEBAPP_RESOURCE_ID \
  --condition "total Http5xx > 10" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action $ACTION_GROUP_ID \
  --description "More than 10 server errors in 5 minutes" \
  --output table

echo -e "${GREEN}✅ Alert Rules created (CPU, Response Time, HTTP 5xx)${NC}"
echo ""

# ==========================================
# PHASE 5: Azure Key Vault
# ==========================================
echo -e "${YELLOW}[Phase 5/6] Creating Azure Key Vault...${NC}"
az keyvault create \
  --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --output table

# Enable Managed Identity
echo -e "${YELLOW}[Phase 5/6] Enabling Managed Identity on Web App...${NC}"
IDENTITY_PRINCIPAL_ID=$(az webapp identity assign \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId --output tsv)

# Grant access to Key Vault
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --object-id $IDENTITY_PRINCIPAL_ID \
  --secret-permissions get list \
  --output table

echo -e "${GREEN}✅ Key Vault created and Managed Identity configured${NC}"
echo ""

# ==========================================
# SUMMARY
# ==========================================
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  APEX — Setup Complete! 🎉${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Resources Created:${NC}"
echo -e "  📦 Resource Group:       $RESOURCE_GROUP"
echo -e "  🖥️  App Service Plan:     $APP_SERVICE_PLAN (S1, Linux)"
echo -e "  🌐 Web App:              https://${WEB_APP_NAME}.azurewebsites.net"
echo -e "  📊 Application Insights: $APP_INSIGHTS_NAME"
echo -e "  📝 Log Analytics:        $LOG_ANALYTICS_WORKSPACE"
echo -e "  🔑 Key Vault:            $KEY_VAULT_NAME"
echo -e "  ⚖️  Auto Scale:           1-5 instances (CPU/Memory based)"
echo -e "  🚨 Alerts:               CPU, Response Time, HTTP 5xx"
echo -e "  📧 Alert Email:          $ALERT_EMAIL"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Set up Azure DevOps pipeline (see azure-pipelines.yml)"
echo -e "  2. Push code to GitHub to trigger first deployment"
echo -e "  3. Run load test: ab -n 10000 -c 100 https://${WEB_APP_NAME}.azurewebsites.net/"
echo ""
