# Azure Container Apps and Jobs Terraform Module

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-blue.svg)](NOTICE) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE) [![OpenTofu Registry](https://img.shields.io/badge/opentofu-registry-yellow.svg)](https://search.opentofu.org/module/CloudAstro/container-apps/azurerm/)

This module manages Azure Container Apps and Jobs, enabling containerized tasks such as event-driven, scheduled, and manual jobs. It supports autoscaling, secure networking, and advanced configurations for microservices and serverless workloads.

## Features

- **Orchestration**: Built on Kubernetes and KEDA (Kubernetes Event-Driven Autoscaling) to manage complex apps and scale containers based on events.
- **Scale-to-Zero**: Automatically scales to zero when not in use, cutting costs for low-traffic or event-driven apps.
- **Traffic Splitting**: Supports routing traffic between multiple service revisions for canary deployments and A/B testing.
- **Environment Integration**: Supports integration with managed APIs and Dapr (Distributed Application Runtime) for streamlined microservices communication in distributed systems.

## Example Usage

This example demonstrates how to provision an Azure Container App with customized settings for scaling, networking, and secure access management.
