# 🚀 APEX — Automated Pipeline for Elastic eXecution

> An end-to-end automated cloud deployment system built on Microsoft Azure that provides CI/CD automation, elastic auto-scaling, and real-time monitoring.

[![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-CI%2FCD-blue?logo=azure-devops)](https://dev.azure.com)
[![Azure](https://img.shields.io/badge/Microsoft%20Azure-Cloud-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![React](https://img.shields.io/badge/React-18.2-61DAFB?logo=react)](https://reactjs.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Azure Services Used](#azure-services-used)
- [Project Structure](#project-structure)
- [Setup Guide](#setup-guide)
- [CI/CD Pipeline](#cicd-pipeline)
- [Auto Scaling](#auto-scaling)
- [Monitoring & Alerts](#monitoring--alerts)
- [Load Testing](#load-testing)
- [Cleanup](#cleanup)

---

## 🎯 Overview

APEX solves three major problems in modern software deployment:

| Problem | APEX Solution |
|---------|---------------|
| **Manual deployment is slow & risky** | Fully automated CI/CD pipeline — code → test → build → deploy in minutes |
| **Fixed resources waste money** | Elastic auto-scaling — pay only for what you use |
| **No visibility into app health** | Real-time monitoring dashboard with automatic alerts |

### Application

This project deploys a **React portfolio website** using the APEX system:
- **Live URL**: [kaviarasan-portfolio-apex.azurewebsites.net](https://kaviarasan-portfolio-apex.azurewebsites.net)
- **Original**: [kaviarasan.vercel.app](https://kaviarasan.vercel.app)

---

## 🏗️ Architecture

```
Developer → GitHub → Azure DevOps Pipeline → Azure App Service
                          ↓                        ↓
                    CI: Build & Test         Azure Monitor
                    CD: Deploy               ↓         ↓
                                        Auto Scale   Alerts
                                        (1-5 inst)   (Email)
```

### Flow

1. Developer pushes code to GitHub (`main` branch)
2. Azure DevOps Pipeline automatically triggers
3. **CI Stage**: Install dependencies → Run tests → Build production bundle
4. **CD Stage**: Deploy build artifact to Azure App Service
5. Azure Monitor continuously tracks performance metrics
6. Auto Scale adjusts instances based on CPU/Memory usage
7. Alerts notify the team if thresholds are breached

---

## ☁️ Azure Services Used

| Service | Purpose |
|---------|---------|
| **Azure App Service** | Hosts the web application on the cloud |
| **Azure DevOps** | Manages the automated CI/CD pipeline |
| **Azure Auto Scale** | Scales resources up/down based on demand |
| **Azure Monitor** | Tracks performance and health in real time |
| **Azure Application Insights** | Deep app analytics and error tracking |
| **Azure Alerts** | Sends automatic notifications on issues |
| **Azure Key Vault** | Keeps secrets and credentials secure |
| **Azure Log Analytics** | Centralized logging and diagnostics |

---

## 📁 Project Structure

```
kaviarasan/
├── azure-pipelines.yml       # CI/CD pipeline definition
├── package.json              # Node.js dependencies
├── public/                   # Static assets
├── src/                      # React source code
│   ├── App.js               # Main application component
│   ├── App.css              # Application styles
│   ├── App.test.js          # Test file
│   ├── index.js             # Entry point
│   └── index.css            # Global styles
├── scripts/
│   ├── setup-azure.sh       # One-click Azure infrastructure setup
│   ├── load-test.sh         # Load testing script (Apache Bench)
│   └── cleanup-azure.sh     # Tear down all Azure resources
└── README.md                # This file
```

---

## 🛠️ Setup Guide

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- [Azure Subscription](https://azure.microsoft.com/free/) (Free tier or Student credits work)
- [Azure DevOps](https://dev.azure.com) account (free)
- [Node.js 20+](https://nodejs.org/) installed
- [Git](https://git-scm.com/) installed

### Step 1: Install Azure CLI

```bash
# macOS
brew install azure-cli

# Verify installation
az --version
```

### Step 2: Login to Azure

```bash
az login
```

### Step 3: Run Infrastructure Setup

```bash
# Edit the email in the script first
nano scripts/setup-azure.sh

# Run the setup
./scripts/setup-azure.sh
```

This creates: Resource Group, App Service Plan (S1), Web App, Auto Scale rules, Application Insights, Log Analytics, Key Vault, and Alert Rules.

### Step 4: Set Up Azure DevOps Pipeline

1. Go to [dev.azure.com](https://dev.azure.com) → Create Organization & Project
2. **Service Connections**:
   - Create **GitHub** connection (authorize your GitHub account)
   - Create **Azure Resource Manager** connection (name it: `azure-apex-connection`)
3. **Create Pipeline**:
   - Source: GitHub → Select `kaviarasankavi/kaviarasan`
   - Config: Existing YAML → Select `azure-pipelines.yml`
   - Save and Run

### Step 5: Trigger First Deployment

```bash
# Make a small change and push
git add .
git commit -m "feat: add APEX CI/CD pipeline"
git push origin main
```

The pipeline will automatically trigger and deploy your app!

---

## 🔄 CI/CD Pipeline

The pipeline (`azure-pipelines.yml`) has two stages:

### Stage 1: Build & Test (CI)
- Install Node.js 20.x
- `npm ci` — Install dependencies
- `npm test` — Run automated tests
- `npm run build` — Create production bundle
- Archive and publish build artifacts

### Stage 2: Deploy (CD)
- Download build artifact
- Deploy to Azure App Service using `AzureWebApp@1` task
- Zero-downtime deployment

**Trigger**: Every push to `main` branch automatically triggers the full pipeline.

---

## ⚖️ Auto Scaling

Configured with the following rules:

| Metric | Threshold | Action | Cooldown |
|--------|-----------|--------|----------|
| CPU % | > 70% (5 min avg) | Scale OUT +1 instance | 5 min |
| CPU % | < 30% (5 min avg) | Scale IN -1 instance | 5 min |
| Memory % | > 80% (5 min avg) | Scale OUT +1 instance | 5 min |
| Memory % | < 40% (5 min avg) | Scale IN -1 instance | 5 min |

**Instance Limits**: Min = 1, Max = 5, Default = 1

---

## 📊 Monitoring & Alerts

### Monitoring Dashboard Metrics
- CPU Usage (line chart)
- Memory Usage (line chart)
- Response Time (line chart)
- HTTP Requests count (bar chart)
- Running Instances (number tile)
- Error Rate / HTTP 5xx (line chart)
- Live Metrics Stream

### Alert Rules
| Alert | Condition | Notification |
|-------|-----------|-------------|
| High CPU | CPU > 80% for 5 min | Email |
| Slow Response | Avg response > 5s for 5 min | Email |
| Server Errors | HTTP 5xx > 10 in 5 min | Email |

---

## 🧪 Load Testing

Use the included load test script to simulate traffic and trigger auto-scaling:

```bash
# Run the load test
./scripts/load-test.sh
```

This sends **10,000 requests** with **100 concurrent connections** using Apache Bench.

While running, monitor:
- **Azure Portal** → App Service Plan → **Scale out** (watch instances increase)
- **Azure Monitor Dashboard** (watch CPU/Memory spike)
- After test ends, instances scale back down in ~10 minutes

---

## 🧹 Cleanup

To delete all Azure resources and stop billing:

```bash
./scripts/cleanup-azure.sh
```

---

## 👤 Author

**Kaviarasan C**
- Portfolio: [kaviarasan.vercel.app](https://kaviarasan.vercel.app)
- GitHub: [@kaviarasankavi](https://github.com/kaviarasankavi)

---

## 📄 License

This project is part of the Cloud Computing course (M.Tech, Semester 2).
