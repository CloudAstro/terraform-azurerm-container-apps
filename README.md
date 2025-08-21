<!-- BEGINNING OF PRE-COMMIT-OPENTOFU DOCS HOOK -->
# Azure Container Apps and Jobs Terraform Module

[![Changelog](https://img.shields.io/badge/changelog-release-green.svg)](CHANGELOG.md) [![Notice](https://img.shields.io/badge/notice-copyright-blue.svg)](NOTICE) [![MIT License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE) [![OpenTofu Registry](https://img.shields.io/badge/opentofu-registry-yellow.svg)](https://search.opentofu.org/module/CloudAstro/azure-container-apps/azurerm/)

This module manages Azure Container Apps and Jobs, enabling containerized tasks such as event-driven, scheduled, and manual jobs. It supports autoscaling, secure networking, and advanced configurations for microservices and serverless workloads.

## Features

- **Orchestration**: Built on Kubernetes and KEDA (Kubernetes Event-Driven Autoscaling) to manage complex apps and scale containers based on events.
- **Scale-to-Zero**: Automatically scales to zero when not in use, cutting costs for low-traffic or event-driven apps.
- **Traffic Splitting**: Supports routing traffic between multiple service revisions for canary deployments and A/B testing.
- **Environment Integration**: Supports integration with managed APIs and Dapr (Distributed Application Runtime) for streamlined microservices communication in distributed systems.

## Example Usage

This example demonstrates how to provision an Azure Container App with customized settings for scaling, networking, and secure access management.

```hcl
resource "azurerm_resource_group" "ca-rg" {
  name     = "rg-container-app-example"
  location = "germanywestcentral"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.ca-rg.location
  name                = "example-user"
  resource_group_name = azurerm_resource_group.ca-rg.name
}

module "ca-environment" {
  source  = "CloudAstro/container-app-environment/azurerm"
  version = "1.0.0"

  name                = "ca-env-dev"
  location            = azurerm_resource_group.ca-rg.location
  resource_group_name = azurerm_resource_group.ca-rg.name
  workload_profile = [
    {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
      maximum_count         = 0
      minimum_count         = 0
    }
  ]
}

##### Container Apps Example #####

module "container_app" {
  source = "../../"

  container_type               = "app"
  name                         = "example-container-app"
  resource_group_name          = azurerm_resource_group.ca-rg.name
  container_app_environment_id = module.ca-environment.container_app_env.id
  workload_profile_name        = "Consumption"
  revision_mode                = "Single"

  tags = {
    environment = "demo"
  }

  identity = {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  template = {
    max_replicas                     = 2
    min_replicas                     = 1
    revision_suffix                  = "v1"
    termination_grace_period_seconds = 30

    container = {
      app = {
        name    = "web"
        image   = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        cpu     = 0.5
        memory  = "1.0Gi"
        command = ["/bin/sh"]
        args    = ["-c", "echo Hello from Container App && sleep 3600"]
        env = [
          {
            name  = "ENVIRONMENT"
            value = "prod"
          }
        ]
        liveness_probe = [
          {
            path                    = "/health"
            port                    = 80
            interval_seconds        = 10
            initial_delay           = 5
            failure_count_threshold = 3
            timeout                 = 2
            host                    = "localhost"
            transport               = "HTTP"
            header = [
              {
                name  = "X-Probe-Check"
                value = "true"
              }

            ]
          }
        ]

        readiness_probe = [
          {
            path                    = "/ready"
            port                    = 80
            interval_seconds        = 5
            initial_delay           = 3
            failure_count_threshold = 3
            success_count_threshold = 1
            timeout                 = 2
            host                    = "localhost"
            transport               = "TCP"
            header = [
              {
                name  = "X-Ready-Check"
                value = "true"
              }
            ]
          }
        ]

        startup_probe = [
          {
            path                    = "/startup"
            port                    = 80
            interval_seconds        = 10
            initial_delay           = 5
            failure_count_threshold = 30
            timeout                 = 2
            host                    = "localhost"
            transport               = "HTTP"
            header = [
              {
                name  = "X-Startup-Check"
                value = "true"
              }
            ]
          }
        ]

        volume_mounts = [
          {
            name     = "app-data"
            path     = "/mnt/data"
            sub_path = "nested/path"
          }
        ]
      }
    }

    init_container = {
      app_init = {
        name    = "init-db-setup"
        image   = "busybox:latest"
        cpu     = 0.25
        memory  = "0.5Gi"
        command = ["/bin/sh", "-c"]
        args    = ["echo Initializing DB; sleep 5;"]

        env = [
          {
            name        = "INIT_MODE"
            value       = "setup"
            secret_name = "test-secret"
          }
        ]

        volume_mounts = [
          {
            name     = "init-volume"
            path     = "/mnt/init"
            sub_path = "init/config"
          }
        ]
      }
    }

    volume = [
      {
        name         = "app-data"
        storage_type = "EmptyDir"
      },
      {
        name         = "init-volume"
        storage_type = "EmptyDir"
      }
    ]

    azure_queue_scale_rules = [
      {
        name         = "scale-queue"
        queue_name   = "my-queue-name"
        queue_length = "5"

        authentication = [
          {
            secret_name       = "azure-storage-secret"
            trigger_parameter = "connection"
          }
        ]
      }
    ]

    custom_scale_rules = [
      {
        name             = "my-custom-scaler"
        custom_rule_type = "azure-servicebus"
        metadata = {
          queueName    = "orders"
          namespace    = "myservicebus"
          messageCount = "10"
        }

        authentication = [
          {
            secret_name       = "azure-storage-secret"
            trigger_parameter = "connection"
          }
        ]
      }
    ]

    http_scale_rules = [
      {
        name                = "http-rule"
        concurrent_requests = 100

        authentication = [
          {
            secret_name       = "azure-storage-secret"
            trigger_parameter = "connection"
          }
        ]
      }
    ]
  }

  ingress = {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    transport                  = "auto"
    client_certificate_mode    = "accept"

    cors = {
      allowed_origins           = ["https://example.com", "https://another.com"]
      allow_credentials_enabled = true
      allowed_headers           = ["Content-Type", "Authorization", "x-api-key"]
      allowed_methods           = ["GET", "POST", "PUT", "DELETE"]
      exposed_headers           = ["X-Example-Header", "X-Another-Header"]
    }

    ip_security_restriction = [
      {
        name             = "AllowInternal"
        description      = "Allow internal subnet"
        ip_address_range = "10.0.0.0/16"
        action           = "Allow"
      }
    ]

    traffic_weight = [
      {
        label           = "prod-v1"
        latest_revision = true
        revision_suffix = "v1"
        percentage      = 100
      }
    ]
  }

  secret = {
    my_inline_secret = {
      name  = "my-inline-secret"
      value = "super-secret-value"
    },
    test-secret = {
      name  = "test-secret"
      value = "super-secret-init-mode"
    }
  }

  dapr = {
    app_id       = "my-dapr-app"
    app_port     = 80
    app_protocol = "http"
  }
}

##### Container Apps Job Example #####

module "container_job" {
  source = "../../"

  container_type               = "job"
  name                         = "example-job"
  location                     = azurerm_resource_group.ca-rg.location
  resource_group_name          = azurerm_resource_group.ca-rg.name
  container_app_environment_id = module.ca-environment.container_app_env.id
  workload_profile_name        = "Consumption"

  tags = {
    environment = "dev"
    app         = "example"
  }

  revision_mode              = "Single"
  replica_timeout_in_seconds = 3600
  replica_retry_limit        = 5

  template = {
    container = {
      echo-example = {
        name    = "example-container"
        cpu     = 0.5
        memory  = "1.0Gi"
        image   = "alpine:3.18"
        args    = ["-c", "echo Hello from Container Job && sleep 3600"]
        command = ["/app/start"]

        env = [
          {
            name  = "ENV_VAR"
            value = "value"
          }
        ]
      }
    }

    init_container = {
      job_init = {
        name    = "init-input-fetch"
        image   = "alpine:3.18"
        cpu     = 0.25
        memory  = "0.5Gi"
        command = ["/bin/sh", "-c"]
        args    = ["echo Fetching input files...; wget -O /mnt/init/data.json https://example.com/data.json; sleep 3"]

        env = [
          {
            name        = "INIT_MODE"
            value       = "download"
            secret_name = "job-init-secret"
          }
        ]

        volume_mounts = [
          {
            name     = "init-volume-job"
            path     = "/mnt/init"
            sub_path = "input/config"
          }
        ]
      }
    }

    volume = [
      {
        name         = "init-volume-job"
        storage_type = "EmptyDir"
      }
    ]
  }

  secret = {
    mysecret = {
      name  = "job-init-secret"
      value = "sensitive-value"
    }
  }

  schedule_trigger_config = [
    {
      cron_expression          = "0 2 * * *" # Every day at 2 AM
      parallelism              = 3
      replica_completion_count = 1
    }
  ]
}
```
<!-- markdownlint-disable MD033 -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_app.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_job.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job) | resource |
| [azurerm_management_lock.lock_app](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_management_lock.lock_job](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) | resource |
| [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |

<!-- markdownlint-disable MD013 -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_container_app_environment_id"></a> [container\_app\_environment\_id](#input\_container\_app\_environment\_id) | * `container_app_environment_id` - (Required) The ID of the Container App Environment within which this Container App/Job should exist. Changing this forces a new resource to be created.<br/><br/>  Example Input:<pre>container_app_environment_id = "/subscriptions/<subscription_id>/resourceGroups/myResourceGroup/providers/Microsoft.App/containerApps/myContainerAppEnvironment"</pre> | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | * `name` - (Required) The name for this Container App/Job. Changing this forces a new resource to be created.<br/><br/>  Example Input:<pre>name = "my-container"</pre> | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | * `resource_group_name` - (Required) The name of the resource group in which the Container App Environment is to be created. Changing this forces a new resource to be created.<br/><br/>  Example Input:<pre>resource_group_name = "myResourceGroup"</pre> | `string` | n/a | yes |
| <a name="input_revision_mode"></a> [revision\_mode](#input\_revision\_mode) | * `revision_mode` - (Required) The revisions operational mode for the Container App. Possible values include `Single` and `Multiple`. In `Single` mode, a single revision is in operation at any given time. In `Multiple` mode, more than one revision can be active at a time and can be configured with load distribution via the `traffic_weight` block in the `ingress` configuration.<br/><br/>  ~> **Note:** This variable is used only for container apps.<br/><br/>  Example Input:<pre>revision_mode = "Single"</pre> | `string` | n/a | yes |
| <a name="input_template"></a> [template](#input\_template) | * `template` - (Required) A `template` block as detailed below.<br/>    * `init_container` - (Optional) The definition of an init container that is part of the group as documented in the `init_container` block below.<br/>      * `args` - (Optional) A list of extra arguments to pass to the container.<br/>      * `command` - (Optional) A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>      * `cpu` - (Optional) The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.<br/><br/>      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.0` / `2.0` or `0.5` / `1.0`<br/>      * `env` - (Optional) One or more `env` blocks as detailed below.<br/>        * `name` - (Required) The name of the environment variable for the container.<br/>        * `secret_name` - (Optional) The name of the secret that contains the value for this environment variable.<br/>        * `value` - (Optional) The value for this environment variable.<br/><br/>        ~> **Note:** This value is ignored if `secret_name` is used<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.<br/><br/>      ~> **Note:** `ephemeral_storage` is currently in preview and not configurable at this time.<br/>      * `image` - (Required) The image to use to create the container.<br/>      * `memory` - (Optional) The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.<br/><br/>      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.25` / `2.5Gi` or `0.75` / `1.5Gi`<br/>      * `name` - (Required) The name of the container<br/>      * `volume_mounts` - (Optional) A `volume_mounts` block as detailed below.<br/>        * `name` - (Required) The name of the Volume to be mounted in the container.<br/>        * `path` - (Required) The path in the container at which to mount this volume.<br/>        * `sub_path` - (Optional) The sub path of the volume to be mounted in the container.<br/>    * `container` - (Required) One or more `container` blocks as detailed below.<br/>      * `args` - (Optional) A list of extra arguments to pass to the container.<br/>      * `command` - (Optional) A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>      * `cpu` - (Required) The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.<br/><br/>      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.0` / `2.0` or `0.5` / `1.0`<br/>      * `env` - (Optional) One or more `env` blocks as detailed below.<br/>        * `name` - (Required) The name of the environment variable for the container.<br/>        * `secret_name` - (Optional) The name of the secret that contains the value for this environment variable.<br/>        * `value` - (Optional) The value for this environment variable.<br/><br/>        ~> **Note:** This value is ignored if `secret_name` is used<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.<br/><br/>      ~> **Note:** `ephemeral_storage` is currently in preview and not configurable at this time.<br/>      * `image` - (Required) The image to use to create the container.<br/>      * `memory` - (Required) The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.<br/>      * `name` - (Required) The name of the container<br/>      * `liveness_probe` - (Optional) A `liveness_probe` block as detailed below.<br/>        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `header` - (Optional) A `header` block as detailed below.<br/>          * `name` - (Required) The HTTP Header Name.<br/>          * `value` - (Required) The HTTP Header value.<br/>        * `host` - (Optional) The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.<br/>        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.<br/>        * `path` - (Optional) The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/><br/><br/>      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.25` / `2.5Gi` or `0.75` / `1.5Gi`<br/>      * `readiness_probe` - (Optional) A `readiness_probe` block as detailed below.<br/>        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - (Optional) A `header` block as detailed below.<br/>          * `name` - (Required) The HTTP Header Name.<br/>          * `value` - (Required) The HTTP Header value.<br/>        * `host` - (Optional) The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - (Optional) The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `success_count_threshold` - (Optional) The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>      * `startup_probe` - (Optional) A `startup_probe` block as detailed below.<br/>        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - (Optional) A `header` block as detailed below.<br/>          * `name` - (Required) The HTTP Header Name.<br/>          * `value` - (Required) The HTTP Header value.<br/>        * `host` - (Optional) The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - (Optional) The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>        * `volume_mounts` - (Optional) A `volume_mounts` block as detailed below.<br/>          * `name` - (Required) The name of the Volume to be mounted in the container.<br/>          * `path` - (Required) The path in the container at which to mount this volume.<br/>          * `sub_path` - (Optional) The sub path of the volume to be mounted in the container.<br/>    * `max_replicas` - (Optional) The maximum number of replicas for this container.<br/>    * `min_replicas` - (Optional) The minimum number of replicas for this container.<br/>    * `azure_queue_scale_rule` - (Optional) One or more `azure_queue_scale_rule` blocks as defined below.<br/>      * `name` - (Required) The name of the Scaling Rule<br/>      * `queue_name` - (Required) The name of the Azure Queue<br/>      * `queue_length` - (Required) The value of the length of the queue to trigger scaling actions.<br/>      * `authentication` - (Required) One or more `authentication` blocks as defined below.<br/>        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>    * `custom_scale_rule` - (Optional) One or more `custom_scale_rule` blocks as defined below.<br/>      * `name` - (Required) The name of the Scaling Rule<br/>      * `custom_rule_type` - (Required) The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.<br/>      * `metadata` - (Required) - A map of string key-value pairs to configure the Custom Scale Rule.<br/>      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.<br/>        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>    * `http_scale_rule` - (Optional) One or more `http_scale_rule` blocks as defined below.<br/>      * `name` - (Required) The name of the Scaling Rule<br/>      * `concurrent_requests` - (Required) - The number of concurrent requests to trigger scaling.<br/>      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.<br/>        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>    * `tcp_scale_rule` - (Optional) One or more `tcp_scale_rule` blocks as defined below.<br/>      * `name` - (Required) The name of the Scaling Rule<br/>      * `concurrent_requests` - (Required) - The number of concurrent requests to trigger scaling.<br/>      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.<br/>        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>    * `revision_suffix` - (Optional) The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.<br/>    * `termination_grace_period_seconds` - (Optional) The time in seconds after the container is sent the termination signal before the process if forcibly killed.<br/>    * `volume` - (Optional) A `volume` block as detailed below.<br/>      * `name` - (Required) The name of the volume.<br/>      * `storage_name` - (Optional) The name of the `AzureFile` storage.<br/>      * `storage_type` - (Optional) The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.<br/><br/>  Example Input:<pre>template = {<br/>  init_container = [<br/>    {<br/>      name = "init-container-1"<br/>      image = "nginx:1.21"<br/>      cpu = 0.25<br/>      memory = "0.5Gi"<br/>      args = ["--debug"]<br/>      command = ["/bin/sh", "-c"]<br/>      env = [<br/>        {<br/>          name = "ENV_VAR_1"<br/>          value = "value1"<br/>        },<br/>        {<br/>          name = "SECRET_ENV_VAR"<br/>          secret_name = "my-secret"<br/>        }<br/>      ]<br/>      volume_mounts = [<br/>        {<br/>          name = "init-volume"<br/>          path = "/init-data"<br/>        }<br/>      ]<br/>    }<br/>  ]<br/>  container = [<br/>    {<br/>      name = "app-container"<br/>      image = "myapp:latest"<br/>      cpu = 1.0<br/>      memory = "2Gi"<br/>      args = ["--start"]<br/>      command = ["/app/entrypoint.sh"]<br/>      env = [<br/>        {<br/>          name = "APP_ENV"<br/>          value = "production"<br/>        }<br/>      ]<br/>      liveness_probe = [<br/>        {<br/>          port = 8080<br/>          path = "/healthz"<br/>          interval_seconds = 10<br/>          timeout = 5<br/>          transport = "HTTP"<br/>        }<br/>      ]<br/>      readiness_probe = [<br/>        {<br/>          port = 8080<br/>          path = "/ready"<br/>          interval_seconds = 10<br/>          success_count_threshold = 1<br/>          transport = "HTTP"<br/>        }<br/>      ]<br/>      startup_probe = [<br/>        {<br/>          port = 8080<br/>          path = "/start"<br/>          interval_seconds = 5<br/>          timeout = 3<br/>          transport = "HTTP"<br/>        }<br/>      ]<br/>      volume_mounts = [<br/>        {<br/>          name = "app-volume"<br/>          path = "/data"<br/>        }<br/>      ]<br/>    }<br/>  ]<br/>  max_replicas = 5<br/>  min_replicas = 1<br/>  revision_suffix = "v1"<br/>  termination_grace_period_seconds = 30<br/>  azure_queue_scale_rules = [<br/>    {<br/>      name = "queue-scale-rule"<br/>      queue_length = 100<br/>      queue_name = "my-queue"<br/>      authentication = [<br/>        {<br/>          secret_name = "queue-auth-secret"<br/>          trigger_parameter = "queueConnectionString"<br/>        }<br/>      ]<br/>    }<br/>  ]<br/>  custom_scale_rules = [<br/>    {<br/>      name = "custom-rule"<br/>      custom_rule_type = "cpu"<br/>      metadata = {<br/>        threshold = "75"<br/>        period = "1m"<br/>      }<br/>      authentication = [<br/>        {<br/>          secret_name = "custom-auth-secret"<br/>          trigger_parameter = "customConnectionString"<br/>        }<br/>      ]<br/>    }<br/>  ]<br/>  http_scale_rules = [<br/>    {<br/>      name = "http-scale-rule"<br/>      concurrent_requests = "100"<br/>      authentication = [<br/>        {<br/>          secret_name = "http-auth-secret"<br/>        }<br/>      ]<br/>    }<br/>  ]<br/>  volume = [<br/>    {<br/>      name = "app-volume"<br/>      storage_name = "my-storage"<br/>      storage_type = "AzureFile"<br/>    }<br/>  ]<br/> }</pre> | <pre>object({<br/>    init_container = optional(map(object({<br/>      args              = optional(list(string))<br/>      command           = optional(list(string))<br/>      cpu               = optional(number)<br/>      ephemeral_storage = optional(string)<br/>      image             = string<br/>      memory            = optional(string)<br/>      name              = string<br/>      env = optional(list(object({<br/>        name        = string<br/>        secret_name = optional(string)<br/>        value       = optional(string)<br/>      })))<br/>      volume_mounts = optional(list(object({<br/>        name     = string<br/>        path     = string<br/>        sub_path = optional(string)<br/>      })))<br/>    })))<br/>    container = map(object({<br/>      args              = optional(list(string))<br/>      command           = optional(list(string))<br/>      cpu               = number<br/>      ephemeral_storage = optional(string)<br/>      image             = string<br/>      memory            = string<br/>      name              = string<br/>      env = optional(list(object({<br/>        name        = string<br/>        secret_name = optional(string)<br/>        value       = optional(string)<br/>      })))<br/>      liveness_probe = optional(list(object({<br/>        failure_count_threshold = optional(number, 3)<br/>        header = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })))<br/>        host             = optional(string)<br/>        initial_delay    = optional(number, 1)<br/>        interval_seconds = optional(number, 10)<br/>        path             = optional(string, "/")<br/>        port             = number<br/>        timeout          = optional(number, 1)<br/>        transport        = string<br/>      })))<br/>      readiness_probe = optional(list(object({<br/>        failure_count_threshold = optional(number, 3)<br/>        header = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })))<br/>        host                    = optional(string)<br/>        initial_delay           = optional(number, 0)<br/>        interval_seconds        = optional(number, 10)<br/>        path                    = optional(string, "/")<br/>        port                    = number<br/>        success_count_threshold = optional(number, 3)<br/>        timeout                 = optional(number, 1)<br/>        transport               = string<br/>      })))<br/>      startup_probe = optional(list(object({<br/>        failure_count_threshold = optional(number, 3)<br/>        header = optional(list(object({<br/>          name  = string<br/>          value = string<br/>        })))<br/>        host             = optional(string)<br/>        initial_delay    = optional(number, 0)<br/>        interval_seconds = optional(number, 10)<br/>        path             = optional(string, "/")<br/>        port             = number<br/>        timeout          = optional(number, 1)<br/>        transport        = string<br/>      })))<br/>      volume_mounts = optional(list(object({<br/>        name     = string<br/>        path     = string<br/>        sub_path = optional(string)<br/>      })))<br/>    }))<br/>    max_replicas = optional(number)<br/>    min_replicas = optional(number)<br/>    azure_queue_scale_rules = optional(list(object({<br/>      name         = string<br/>      queue_name   = string<br/>      queue_length = number<br/>      authentication = list(object({<br/>        secret_name       = string<br/>        trigger_parameter = string<br/>      }))<br/>    })))<br/>    custom_scale_rules = optional(list(object({<br/>      name             = string<br/>      custom_rule_type = string<br/>      metadata         = map(string)<br/>      authentication = optional(list(object({<br/>        secret_name       = string<br/>        trigger_parameter = string<br/>      })))<br/>    })))<br/>    http_scale_rules = optional(list(object({<br/>      name                = string<br/>      concurrent_requests = string<br/>      authentication = optional(list(object({<br/>        secret_name       = string<br/>        trigger_parameter = optional(string)<br/>      })))<br/>    })))<br/>    tcp_scale_rules = optional(list(object({<br/>      name                = string<br/>      concurrent_requests = string<br/>      authentication = optional(list(object({<br/>        secret_name       = string<br/>        trigger_parameter = optional(string)<br/>      })))<br/>    })))<br/>    revision_suffix                  = optional(string)<br/>    termination_grace_period_seconds = optional(number)<br/>    volume = optional(list(object({<br/>      name          = string<br/>      storage_name  = optional(string)<br/>      storage_type  = optional(string, "EmptyDir")<br/>      mount_options = optional(string)<br/>    })))<br/>  })</pre> | n/a | yes |
| <a name="input_container_type"></a> [container\_type](#input\_container\_type) | * `container_type` - (Required) Container Type must be either `app` or `job`, default value is `app`.<br/><br/>  Example Input:<pre>container_type = "app"</pre> | `string` | `"app"` | no |
| <a name="input_dapr"></a> [dapr](#input\_dapr) | * `dapr` - (Optional) A `dapr` block as detailed below.<br/>    * `app_id` - (Required) The Dapr Application Identifier.<br/>    * `app_port` - (Optional) The port which the application is listening on. This is the same as the `ingress` port.<br/>    * `app_protocol` - (Optional) The protocol for the app. Possible values include `http` and `grpc`. Defaults to `http`.<br/><br/>  Example Input:<pre>dapr = {<br/>  app_id       = "my-dapr-app"<br/>  app_port     = 5000<br/>  app_protocol = "http"<br/>  }</pre> | <pre>object({<br/>    app_id       = string<br/>    app_port     = optional(number)<br/>    app_protocol = optional(string, "http")<br/>  })</pre> | `null` | no |
| <a name="input_event_trigger_config"></a> [event\_trigger\_config](#input\_event\_trigger\_config) | * `event_trigger_config` - (Optional) A `event_trigger_config` block as defined below.<br/>    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.<br/>    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.<br/>    * `scale` - (Optional) A `scale` block as defined below.<br/>      * `max_executions` - (Optional) Maximum number of job executions that are created for a trigger.<br/>      * `min_executions` - (Optional) Minimum number of job executions that are created for a trigger.<br/>      * `polling_interval_in_seconds` - (Optional) Interval to check each event source in seconds.<br/>      * `rules` - (Optional) A `rules` block as defined below.<br/>        * `name` - (Optional) Name of the scale rule.<br/>        * `custom_rule_type` - (Optional) Type of the scale rule.<br/>        * `metadata` - (Optional) Metadata properties to describe the scale rule.<br/>        * `authentication` - (Optional) A `authentication` block as defined below.<br/>          * `secret_name` - (Optional) Name of the secret from which to pull the auth params.<br/>          * `trigger_parameter` - (Optional) Trigger Parameter that uses the secret.<br/><br/>  ~> **Note:** This variable is used only for container job.<br/><br/>  Example Input:<pre>event_trigger_config = [<br/>    {<br/>      parallelism              = 2<br/>      replica_completion_count = 1<br/>      scale = {<br/>        my_scale_rule = {<br/>          max_executions              = 5<br/>          min_executions              = 1<br/>          polling_interval_in_seconds = 30<br/>          rules = {<br/>            my_rule = {<br/>              name             = "queue-scale-rule"<br/>              custom_rule_type = "azure-queue"<br/>              metadata = {<br/>                queueName   = "my-queue"<br/>                queueLength = "5"<br/>              }<br/>              authentication = {<br/>                auth1 = {<br/>                  secret_name       = "azure-storage-secret"<br/>                  trigger_parameter = "connection"<br/>                }<br/>              }<br/>            }<br/>          }<br/>        }<br/>      }<br/>    }<br/>  ]</pre> | <pre>list(object({<br/>    parallelism              = optional(number)<br/>    replica_completion_count = optional(number)<br/>    scale = map(object({<br/>      max_executions              = optional(number)<br/>      min_executions              = optional(number)<br/>      polling_interval_in_seconds = optional(number)<br/>      rules = map(object({<br/>        name             = optional(string)<br/>        custom_rule_type = optional(string)<br/>        metadata         = map(string)<br/>        authentication = map(object({<br/>          secret_name       = optional(string)<br/>          trigger_parameter = optional(string)<br/>        }))<br/>      }))<br/>    }))<br/>  }))</pre> | `null` | no |
| <a name="input_identity"></a> [identity](#input\_identity) | * `identity` - (Optional) An `identity` block as detailed below.<br/>    * `system_assigned` - (Required) The type of managed identity to assign. Possible values are `SystemAssigned`, `UserAssigned`, and `SystemAssigned, UserAssigned` (to enable both).<br/>    * `identity_ids` - (Optional) - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`.<br/><br/>  Example Inputs:<pre>managed_identities = {<br/>    system_assigned            = true<br/>    user_assigned_resource_ids = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"<br/>  }</pre> | <pre>object({<br/>    type         = string<br/>    identity_ids = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | * `ingress` - (Optional) An `ingress` block as detailed below.<br/>    * `allow_insecure_connections` - (Optional) Should this ingress allow insecure connections?<br/>    * `cors` - (Optional) A `cors` block as defined below.<br/>      * `allowed_origins` - (Required) Specifies the list of origins that are allowed to make cross-origin calls.<br/>      * `allow_credentials_enabled` - (Optional) Whether user credentials are allowed in the cross-origin request is enabled. Defaults to `false`.<br/>      * `allowed_headers` - (Optional) Specifies the list of request headers that are permitted in the actual request.<br/>      * `allowed_methods` - (Optional) Specifies the list of HTTP methods are allowed when accessing the resource in a cross-origin request.<br/>      * `exposed_headers` - (Optional) Specifies the list of headers exposed to the browser in the response to a cross-origin request.<br/>      * `max_age_in_seconds` - (Optional) Specifies the number of seconds that the browser can cache the results of a preflight request.<br/>    * `fqdn` - The FQDN of the ingress.<br/>    * `external_enabled` - (Optional) Are connections to this Ingress from outside the Container App Environment enabled? Defaults to `false`.<br/>    * `ip_security_restriction` - (Optional) One or more `ip_security_restriction` blocks for IP-filtering rules as defined below.<br/>      * `action` - (Required) The IP-filter action. `Allow` or `Deny`.<br/><br/>      ~> **Note:** The `action` types in an all `ip_security_restriction` blocks must be the same for the `ingress`, mixing `Allow` and `Deny` rules is not currently supported by the service.<br/>      * `description` - (Optional) Describe the IP restriction rule that is being sent to the container-app.<br/>      * `ip_address_range` - (Required) The incoming IP address or range of IP addresses (in CIDR notation).<br/>      * `name` - (Required) Name for the IP restriction rule.<br/>    * `target_port` - (Required) The target port on the container for the Ingress traffic.<br/>    * `exposed_port` - (Optional) The exposed port on the container for the Ingress traffic.<br/><br/>    ~> **Note:** `exposed_port` can only be specified when `transport` is set to `tcp`.<br/>    * `traffic_weight` - (Required) One or more `traffic_weight` blocks as detailed below.<br/><br/>      ~> **Note:** This block only applies when `revision_mode` is set to `Multiple`.<br/>      * `label` - (Optional) The label to apply to the revision as a name prefix for routing traffic.<br/>      * `latest_revision` - (Optional) This traffic Weight applies to the latest stable Container Revision. At most only one `traffic_weight` block can have the `latest_revision` set to `true`.<br/>      * `revision_suffix` - (Optional) The suffix string to which this `traffic_weight` applies.<br/><br/>      ~> **Note:** If `latest_revision` is `false`, the `revision_suffix` shall be specified.<br/>      * `percentage` - (Required) The percentage of traffic which should be sent this revision.<br/><br/>      ~> **Note:** The cumulative values for `weight` must equal 100 exactly and explicitly, no default weights are assumed.<br/>    * `transport` - (Optional) The transport method for the Ingress. Possible values are `auto`, `http`, `http2` and `tcp`. Defaults to `auto`.<br/><br/>    ~> **Note:**  if `transport` is set to `tcp`, `exposed_port` and `target_port` should be set at the same time.<br/>    * `client_certificate_mode` - (Optional) The client certificate mode for the Ingress. Possible values are `require`, `accept`, and `ignore`.<br/><br/>  Example Input:<pre>ingress = {<br/>    ingress1 = {<br/>  allow_insecure_connections = false<br/>  fqdn                       = "app.example.com"<br/>  cors = {<br/>    allowed_origins           = ["https://example.com", "https://app.example.com"]<br/>    allow_credentials_enabled = true<br/>    allowed_headers           = ["Content-Type", "Authorization"]<br/>    allowed_methods           = ["GET", "POST", "OPTIONS"]<br/>    exposed_headers           = ["X-Custom-Header"]<br/>    max_age_in_seconds        = 3600<br/>  }<br/>  external_enabled           = true<br/>  target_port                = 8080<br/>  exposed_port               = 80<br/>  transport                  = "http"<br/>  client_certificate_mode = "accept"<br/>  custom_domain = {<br/>    certificate_binding_type = "SNI"<br/>    certificate_id           = "cert-12345"<br/>    name                     = "custom.example.com"<br/>  }<br/>  ip_security_restriction = [<br/>    {<br/>      action           = "Allow"<br/>      description      = "Allow traffic from internal network"<br/>      ip_address_range = "10.0.0.0/24"<br/>      name             = "internal-allow"<br/>    },<br/>    {<br/>      action           = "Deny"<br/>      description      = "Block traffic from specific IP range"<br/>      ip_address_range = "192.168.1.0/24"<br/>      name             = "restricted-block"<br/>    }<br/>  ]<br/>  traffic_weight = [<br/>    {<br/>      label           = "v1"<br/>      latest_revision = false<br/>      revision_suffix = "rev1"<br/>      percentage      = 50<br/>    },<br/>    {<br/>      label           = "v2"<br/>      latest_revision = true<br/>      percentage      = 50<br/>    }<br/>   ]<br/>   }<br/>  }</pre> | <pre>object({<br/>    allow_insecure_connections = optional(bool)<br/>    external_enabled           = optional(bool, false)<br/>    fqdn                       = optional(string)<br/>    cors = optional(object({<br/>      allowed_origins           = optional(list(string))<br/>      allow_credentials_enabled = optional(bool, false)<br/>      allowed_headers           = optional(list(string))<br/>      allowed_methods           = optional(list(string))<br/>      exposed_headers           = optional(list(string))<br/>      max_age_in_seconds        = optional(number)<br/>    }))<br/>    ip_security_restriction = optional(list(object({<br/>      action           = string<br/>      description      = optional(string)<br/>      ip_address_range = string<br/>      name             = string<br/>    })))<br/>    target_port  = number<br/>    exposed_port = optional(number)<br/>    traffic_weight = list(object({<br/>      label           = optional(string)<br/>      latest_revision = optional(bool)<br/>      revision_suffix = optional(string)<br/>      percentage      = number<br/>    }))<br/>    transport               = optional(string, "auto")<br/>    client_certificate_mode = optional(string)<br/>    custom_domain = optional(object({<br/>      certificate_binding_type = optional(string)<br/>      certificate_id           = string<br/>      name                     = string<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_location"></a> [location](#input\_location) | * `location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.<br/><br/>  ~> **Note:** For Container Apps, the location is the same as the Environment in which it is deployed.<br/><br/>  Example Input:<pre>name = "germanywestcetnral"</pre> | `string` | `null` | no |
| <a name="input_lock"></a> [lock](#input\_lock) | * `lock` block as detailed below.<br/>    * `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.<br/>    * `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.<br/><br/>  Example Input:<pre>lock = {<br/>    kind = "CanNotDelete"<br/>    name = "my-resource-lock"<br/>  }</pre> | <pre>object({<br/>    kind = string<br/>    name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_manual_trigger_config"></a> [manual\_trigger\_config](#input\_manual\_trigger\_config) | * `manual_trigger_config` - (Optional) A `manual_trigger_config` block as defined below.<br/>    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.<br/>    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.<br/><br/>  ~> **Note:** This variable is used only for container job.<br/><br/>  Example Input:<pre>manual_trigger_config = {<br/>    parallelism              = 5<br/>    replica_completion_count = 3<br/>  }</pre> | <pre>object({<br/>    parallelism              = optional(number)<br/>    replica_completion_count = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_registry"></a> [registry](#input\_registry) | * `registries` - (Optional) A `template` block as detailed below.<br/>    * `server` - (Required) The hostname for the Container Registry.<br/>    The authentication details must also be supplied, `identity` and `username`/`password_secret_name` are mutually exclusive.<br/>    * `identity` - (Optional) Resource ID for the User Assigned Managed identity to use when pulling from the Container Registry.<br/><br/>    ~> **Note:** The Resource ID must be of a User Assigned Managed identity defined in an `identity` block.<br/>    * `password_secret_name` - (Optional) The name of the Secret Reference containing the password value for this user on the Container Registry, `username` must also be supplied.<br/>    * `username` - (Optional) The username to use for this Container Registry, `password_secret_name` must also be supplied..<br/><br/>  Example Input:<pre>registries = {<br/>    registry1 = {<br/>    server               = "mycontainerregistry.azurecr.io"<br/>    username             = "myregistryuser"<br/>    password_secret_name = "myregistrysecret"<br/>    },<br/>    registry2 = {<br/>    server   = "anotherregistry.azurecr.io"<br/>    identity = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myIdentity"<br/>    }<br/>  }</pre> | <pre>map(object({<br/>    server               = string<br/>    identity             = optional(string)<br/>    password_secret_name = optional(string)<br/>    username             = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_replica_retry_limit"></a> [replica\_retry\_limit](#input\_replica\_retry\_limit) | * `replica_retry_limit` - (Optional) The maximum number of times a replica is allowed to retry.<br/><br/>  ~> **Note:** This variable is used only for container job.<br/><br/>  Example Input:<pre>replica_retry_limit = 5</pre> | `number` | `null` | no |
| <a name="input_replica_timeout_in_seconds"></a> [replica\_timeout\_in\_seconds](#input\_replica\_timeout\_in\_seconds) | * `replica_timeout_in_seconds` - (Required) The maximum number of seconds a replica is allowed to run.<br/><br/>  ~> **Note:** This variable is used only for container job.<br/><br/>  Example Input:<pre>replica_timeout_in_seconds = 3600</pre> | `number` | `null` | no |
| <a name="input_role_assignment"></a> [role\_assignment](#input\_role\_assignment) | * `role_assignment` block as detailed below.<br/>    * `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.<br/>    * `principal_id` - The ID of the principal to assign the role to.<br/>    * `description` - (Optional) The description of the role assignment.<br/>    * `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.<br/>    * `condition` - (Optional) The condition which will be used to scope the role assignment.<br/>    * `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.<br/>    * `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.<br/>    * `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.<br/><br/>  ~> **Note:** only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.<br/><br/>  Example Input:<pre>role_assignments = {<br/>  "assignment1" = {<br/>    role_definition_id_or_name             = "Contributor"<br/>    principal_id                           = "11111111-2222-3333-4444-555555555555"<br/>    description                            = "Granting contributor access"<br/>    skip_service_principal_aad_check       = false<br/>    principal_type                         = "User"<br/>  },<br/>  "assignment2" = {<br/>    role_definition_id_or_name             = "Reader"<br/>    principal_id                           = "66666666-7777-8888-9999-000000000000"<br/>    skip_service_principal_aad_check       = true<br/>    principal_type                         = "ServicePrincipal"<br/>  }<br/> }</pre> | <pre>map(object({<br/>    role_definition_id_or_name             = string<br/>    principal_id                           = string<br/>    description                            = optional(string)<br/>    skip_service_principal_aad_check       = optional(bool, false)<br/>    condition                              = optional(string)<br/>    condition_version                      = optional(string)<br/>    delegated_managed_identity_resource_id = optional(string)<br/>    principal_type                         = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_schedule_trigger_config"></a> [schedule\_trigger\_config](#input\_schedule\_trigger\_config) | * `schedule_trigger_config` - (Optional) A `schedule_trigger_config` block as defined below.<br/><br/>  ~> **Note:** Only one of `manual_trigger_config`, `event_trigger_config` or `schedule_trigger_config` can be specified.<br/>    * `cron_expression` - (Required) Cron formatted repeating schedule of a Cron Job.<br/>    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.<br/>    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.<br/><br/>  ~> **Note:** This variable is used only for container job.<br/><br/>  Example Input:<pre>schedule_trigger_config = [<br/>    {<br/>      cron_expression          = "0 0 * * *"<br/>      parallelism              = 5<br/>      replica_completion_count = 3<br/>    }<br/>  ]</pre> | <pre>list(object({<br/>    cron_expression          = string<br/>    parallelism              = optional(number)<br/>    replica_completion_count = optional(number)<br/>  }))</pre> | `null` | no |
| <a name="input_secret"></a> [secret](#input\_secret) | * `secrets` - (Optional) A `secrets` block as detailed below.<br/>    * `name` - (Required) The secret name.<br/>    * `identity` - (Optional) The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.<br/><br/>    ~> **Note:** `identity` must be used together with `key_vault_secret_id`<br/>    * `key_vault_secret_id` - (Optional) The ID of a Key Vault secret. This can be a versioned or version-less ID.<br/><br/>    ~> **Note:** When using `key_vault_secret_id`, `ignore_changes` should be used to ignore any changes to `value`.<br/>    * `value` - (Optional) The value for this secret.<br/><br/>    ~> **Note:** `value` will be ignored if `key_vault_secret_id` and `identity` are provided.<br/><br/>  Example Input:<pre>secrets = {<br/>  "db_password" = {<br/>    identity            = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myIdentity"<br/>    key_vault_secret_id = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.KeyVault/vaults/myKeyVault/secrets/dbPassword"<br/>    name                = "db_password"<br/>  },<br/>  "api_key" = {<br/>    name  = "api_key"<br/>    value = "s3cr3tAPIkey123"<br/>  },<br/>  "system_secret" = {<br/>    identity = "System"<br/>    name     = "system_secret_name"<br/>  }<br/> }</pre> | <pre>map(object({<br/>    name                = string<br/>    identity            = optional(string)<br/>    key_vault_secret_id = optional(string)<br/>    value               = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | * `tags` - (Optional) A map of tags to associate with the network and subnets.<br/><br/>  Example Input:<pre>tags = {<br/>    "environment" = "production"<br/>    "department"  = "IT"<br/>  }</pre> | `map(string)` | `null` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | * `timeouts` block as detailed below.<br/>    * `create` - (Defaults to 30 minutes) Used when creating the Container App/Job.<br/>    * `delete` - (Defaults to 30 minutes) Used when deleting the Container App/Job.<br/>    * `read` - (Defaults to 5 minutes) Used when retrieving the Container App/Job.<br/>    * `update` - (Defaults to 30 minutes) Used when updating the Container App/Job.<br/><br/>  Example Input:<pre>container_app_timeouts = {<br/>    create = "45m"<br/>    delete = "30m"<br/>    read   = "10m"<br/>    update = "40m"<br/>  }</pre> | <pre>object({<br/>    create = optional(string, "30")<br/>    delete = optional(string, "5")<br/>    read   = optional(string, "30")<br/>    update = optional(string, "30")<br/>  })</pre> | `null` | no |
| <a name="input_workload_profile_name"></a> [workload\_profile\_name](#input\_workload\_profile\_name) | * `workload_profile_name` - (Optional) The name of the Workload Profile in the Container App Environment to place this Container App/Job.<br/><br/>  Example Input:<pre>workload_profile_name = "standard-workload-profile"</pre> | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_container_app"></a> [container\_app](#output\_container\_app) | * `container_app_environment_id` - The ID of the Container App Environment this Container App is linked to.<br/>    * `name` - The name of the Container App.<br/>    * `resource_group_name` - The name of the Resource Group where this Container App exists.<br/>    * `revision_mode` - The revision mode of the Container App.<br/>    * `workload_profile_name` - The name of the Workload Profile in the Container App Environment in which this Container App is running.<br/>    * `tags` - A mapping of tags to assign to the Container App.<br/><br/>    A `template` block exports the following:<br/>      * `init_container` -  One or more `init_container` blocks detailed below.<br/>      * `args` - A list of extra arguments to pass to the container.<br/>      * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>      * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`.<br/>      * `env` - One or more `env` blocks as detailed below.<br/>        * `name` - The name of the environment variable for the container.<br/>        * `secret_name` - The name of the secret that contains the value for this environment variable.<br/>        * `value` - The value for this environment variable.<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App.<br/>      * `image` - The image to use to create the container.<br/>      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`.<br/>      * `name` - The name of the container<br/>      * `volume_mounts` - A `volume_mounts` block as detailed below.<br/>        * `name` - The name of the Volume to be mounted in the container.<br/>        * `path` - The path in the container at which to mount this volume.<br/>        * `sub_path` - The sub path of the volume to be mounted in the container.<br/>      * `container` - One or more `container` blocks as detailed below.<br/>        * `args` - A list of extra arguments to pass to the container.<br/>        * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>        * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`.<br/>      * `env` - One or more `env` blocks as detailed below.<br/>        * `name` - The name of the environment variable for the container.<br/>        * `secret_name` - The name of the secret that contains the value for this environment variable.<br/>        * `value` - The value for this environment variable.<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App.<br/>      * `image` - The image to use to create the container.<br/>      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`.<br/>      * `name` - The name of the container<br/>      * `liveness_probe` - A `liveness_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.<br/>        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>      * `readiness_probe` - A `readiness_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `success_count_threshold` - The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>      * `startup_probe` - A `startup_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>        * `volume_mounts` - A `volume_mounts` block as detailed below.<br/>          * `name` - The name of the Volume to be mounted in the container.<br/>          * `path` - The path in the container at which to mount this volume.<br/>          * `sub_path` - The sub path of the volume to be mounted in the container.<br/>      * `max_replicas` - The maximum number of replicas for this container.<br/>      * `min_replicas` - The minimum number of replicas for this container.<br/>      * `azure_queue_scale_rule` - One or more `azure_queue_scale_rule` blocks as defined below.<br/>      * `name` - The name of the Scaling Rule<br/>      * `queue_name` - The name of the Azure Queue<br/>      * `queue_length` - The value of the length of the queue to trigger scaling actions.<br/>      * `authentication` - One or more `authentication` blocks as defined below.<br/>        * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `custom_scale_rule` - One or more `custom_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `custom_rule_type` - The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.<br/>        * `metadata` -  A map of string key-value pairs to configure the Custom Scale Rule.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `http_scale_rule` - One or more `http_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `concurrent_requests` - The number of concurrent requests to trigger scaling.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `tcp_scale_rule` - One or more `tcp_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `concurrent_requests` - The number of concurrent requests to trigger scaling.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `revision_suffix` - The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.<br/>      * `termination_grace_period_seconds` - The time in seconds after the container is sent the termination signal before the process if forcibly killed.<br/>      * `volume` - A `volume` block as detailed below.<br/>        * `name` - The name of the volume.<br/>        * `storage_name` - The name of the `AzureFile` storage.<br/>        * `storage_type` - The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.<br/><br/>    An `identity` block supports the following:<br/>        * `type` - The type of managed identity to assign. Possible values are UserAssigned and SystemAssigned<br/>        * `identity_ids` - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when type is set to UserAssigned.<br/><br/>    A `secrets` block supports the following:<br/>        * `name` - The secret name.<br/>        * `identity` - The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.<br/>        * `key_vault_secret_id` - The ID of a Key Vault secret. This can be a versioned or version-less ID.<br/>        * `value` - The value for this secret.<br/><br/>    An `ingress` block supports the following:<br/>        * `allow_insecure_connections` - Should this ingress allow insecure connections?<br/>        * `cors` - A `cors` block as defined below.<br/>            * `allowed_origins` - Specifies the list of origins that are allowed to make cross-origin calls.<br/>            * `allow_credentials_enabled` - Whether user credentials are allowed in the cross-origin request is enabled. Defaults to `false`.<br/>            * `allowed_headers` - Specifies the list of request headers that are permitted in the actual request.<br/>            * `allowed_methods` - Specifies the list of HTTP methods are allowed when accessing the resource in a cross-origin request.<br/>            * `exposed_headers` - Specifies the list of headers exposed to the browser in the response to a cross-origin request.<br/>            * `max_age_in_seconds` - Specifies the number of seconds that the browser can cache the results of a preflight request.<br/>        * `fqdn` - The FQDN of the ingress.<br/>        * `external_enabled` - Are connections to this Ingress from outside the Container App Environment enabled? Defaults to `false`.<br/>        * `ip_security_restriction` - One or more `ip_security_restriction` blocks for IP-filtering rules as defined below.<br/>            * `action` - The IP-filter action. `Allow` or `Deny`.<br/>        * `description` - Describe the IP restriction rule that is being sent to the container-app.<br/>        * `ip_address_range` - The incoming IP address or range of IP addresses (in CIDR notation).<br/>        * `name` - Name for the IP restriction rule.<br/>        * `target_port` - The target port on the container for the Ingress traffic.<br/>        * `exposed_port` - The exposed port on the container for the Ingress traffic.<br/>        * `traffic_weight` - One or more `traffic_weight` blocks as detailed below.<br/>        * `label` - The label to apply to the revision as a name prefix for routing traffic.<br/>        * `latest_revision` - This traffic Weight applies to the latest stable Container Revision. At most only one `traffic_weight` block can have the `latest_revision` set to `true`.<br/>        * `revision_suffix` - The suffix string to which this `traffic_weight` applies.<br/>        * `percentage` -  The percentage of traffic which should be sent this revision.<br/>        * `transport` - The transport method for the Ingress. Possible values are `auto`, `http`, `http2` and `tcp`. Defaults to `auto`.<br/>        * `client_certificate_mode` - The client certificate mode for the Ingress. Possible values are `require`, `accept`, and `ignore`.<br/><br/>    A `dapr` block supports the following:<br/>        * `app_id` - The Dapr Application Identifier.<br/>        * `app_port` - The port which the application is listening on. This is the same as the `ingress` port.<br/>        * `app_protocol` - The protocol for the app. Possible values include `http` and `grpc`. Defaults to `http`.<br/><br/>    A `registry` block supports the following:<br/>        * `server` - The hostname for the Container Registry.<br/>        * `username` - The username to use for this Container Registry, `password_secret_name` must also be supplied..<br/>        * `password_secret_name` - The name of the Secret Reference containing the password value for this user on the Container Registry, username must also be supplied.<br/>        * `identity` - Resource ID for the User Assigned Managed identity to use when pulling from the Container Registry.<br/><br/>  Example output:<pre>output "name" {<br/>    value = module.module_name.container_app.name<br/>  }</pre> |
| <a name="output_container_job"></a> [container\_job](#output\_container\_job) | * `name` - Specifies the name of the Container App Job. Changing this forces a new resource to be created.<br/>   * `resource_group_name` - The name of the resource group in which to create the resource. Changing this forces a new resource to be created.<br/>   * `location` - Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.<br/>   * `environment_id` - The ID of the Container Apps Environment in which to create the Container App Job. Changing this forces a new resource to be created.<br/>   * `replica_timeout_in_seconds` - The maximum number of seconds a replica is allowed to run.<br/>   * `workload_profile_name` - The name of the workload profile to use for the Container App Job.<br/>   * `replica_retry_limit` - The maximum number of times a replica is allowed to retry.<br/>   * `tags` - A mapping of tags to assign to the resource.<br/><br/>    A `template` block supports the following:<br/>      * `init_container` - The definition of an init container that is part of the group as documented in the `init_container` block below.<br/>      * `args` - A list of extra arguments to pass to the container.<br/>      * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>      * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.<br/>      * `env` - One or more `env` blocks as detailed below.<br/>        * `name` - The name of the environment variable for the container.<br/>        * `secret_name` - The name of the secret that contains the value for this environment variable.<br/>        * `value` - The value for this environment variable.<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.<br/>      * `image` - The image to use to create the container.<br/>      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.<br/>      * `name` - The name of the container<br/>      * `volume_mounts` - A `volume_mounts` block as detailed below.<br/>        * `name` - The name of the Volume to be mounted in the container.<br/>        * `path` - The path in the container at which to mount this volume.<br/>        * `sub_path` - The sub path of the volume to be mounted in the container.<br/>      * `container` - One or more `container` blocks as detailed below.<br/>        * `args` - A list of extra arguments to pass to the container.<br/>        * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.<br/>        * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.<br/>      * `env` - One or more `env` blocks as detailed below.<br/>        * `name` - The name of the environment variable for the container.<br/>        * `secret_name` - The name of the secret that contains the value for this environment variable.<br/>        * `value` - The value for this environment variable.<br/>      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.<br/>      * `image` - The image to use to create the container.<br/>      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.<br/>      * `name` - The name of the container<br/>      * `liveness_probe` - A `liveness_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.<br/>        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` -  The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>      * `readiness_probe` - A `readiness_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `success_count_threshold` - The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>      * `startup_probe` - A `startup_probe` block as detailed below.<br/>        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.<br/>        * `header` - A `header` block as detailed below.<br/>          * `name` - The HTTP Header Name.<br/>          * `value` - The HTTP Header value.<br/>        * `host` - The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.<br/>        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.<br/>        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`<br/>        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.<br/>        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.<br/>        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.<br/>        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.<br/>        * `volume_mounts` - A `volume_mounts` block as detailed below.<br/>          * `name` - The name of the Volume to be mounted in the container.<br/>          * `path` - The path in the container at which to mount this volume.<br/>          * `sub_path` - The sub path of the volume to be mounted in the container.<br/>      * `max_replicas` - The maximum number of replicas for this container.<br/>      * `min_replicas` - The minimum number of replicas for this container.<br/>      * `azure_queue_scale_rule` - One or more `azure_queue_scale_rule` blocks as defined below.<br/>      * `name` - The name of the Scaling Rule<br/>      * `queue_name` - The name of the Azure Queue<br/>      * `queue_length` - The value of the length of the queue to trigger scaling actions.<br/>      * `authentication` - One or more `authentication` blocks as defined below.<br/>        * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>        * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `custom_scale_rule` - One or more `custom_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `custom_rule_type` - The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.<br/>        * `metadata` -  A map of string key-value pairs to configure the Custom Scale Rule.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `http_scale_rule` - One or more `http_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `concurrent_requests` - The number of concurrent requests to trigger scaling.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `tcp_scale_rule` - One or more `tcp_scale_rule` blocks as defined below.<br/>        * `name` - The name of the Scaling Rule<br/>        * `concurrent_requests` - The number of concurrent requests to trigger scaling.<br/>        * `authentication` - Zero or more `authentication` blocks as defined below.<br/>            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.<br/>            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.<br/>      * `revision_suffix` - The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.<br/>      * `termination_grace_period_seconds` - The time in seconds after the container is sent the termination signal before the process if forcibly killed.<br/>      * `volume` - A `volume` block as detailed below.<br/>        * `name` - The name of the volume.<br/>        * `storage_name` - The name of the `AzureFile` storage.<br/>        * `storage_type` - The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.<br/><br/>    An `identity` block supports the following:<br/>        * `type` - The type of managed identity to assign. Possible values are `SystemAssigned`, `UserAssigned`, and `SystemAssigned, UserAssigned` (to enable both).<br/>        * `identity_ids` - - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`.<br/><br/>    A `secrets` block supports the following:<br/>        * `name` - The secret name.<br/>        * `identity` - The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.<br/>        * `key_vault_secret_id` - The ID of a Key Vault secret. This can be a versioned or version-less ID.<br/>        * `value` - The value for this secret.<br/><br/>    A `manual_trigger_config` block supports the following:<br/>        * `parallelism` - Number of parallel replicas of a job that can run at a given time.<br/>        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.<br/><br/>    A `event_trigger_config` block supports the following:<br/>        * `parallelism` - Number of parallel replicas of a job that can run at a given time.<br/>        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.<br/>        * `scale` - A `scale` block as defined below.<br/>            * `max_executions` - Maximum number of job executions that are created for a trigger.<br/>            * `min_executions` - Minimum number of job executions that are created for a trigger.<br/>            * `polling_interval_in_seconds` - Interval to check each event source in seconds.<br/>            * `rules` - A `rules` block as defined below.<br/>                * `name` - Name of the scale rule.<br/>                * `custom_rule_type` - Type of the scale rule.<br/>                * `metadata` - Metadata properties to describe the scale rule.<br/>                * `authentication` - A `authentication` block as defined below.<br/>                    * `secret_name` - Name of the secret from which to pull the auth params.<br/>                    * `trigger_parameter` - Trigger Parameter that uses the secret.<br/><br/>    A `schedule_trigger_config` block supports the following:<br/>        * `cron_expression` - Cron formatted repeating schedule of a Cron Job.<br/>        * `parallelism` - Number of parallel replicas of a job that can run at a given time.<br/>        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.<br/><br/>  Example output:<pre>output "name" {<br/>    value = module.module_name.azurerm_container_app_job.name<br/>   }</pre> |

## Modules

No modules.

# Additional Resources

For more details on configuring and managing Azure Container Apps and Azure Container App Jobs, refer to the [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/) and [Azure Container Apps Jobs Documentation](https://learn.microsoft.com/azure/container-apps/jobs-overview). This module manages Azure Container Apps and Container App Jobs, supporting secure networking, autoscaling, and event-driven workloads for microservices and task-based architectures.

## Resources
- [Terraform Azure Provider Documentation for Container Apps](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_apps)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Container Apps Networking](https://learn.microsoft.com/azure/container-apps/networking)
- [Terraform Azure Provider Documentation for Container App Jobs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_job)

## Notes
- Use Scale-to-Zero to optimize costs for idle or low-traffic workloads.
- Apply event or schedule-based triggers using KEDA for dynamic job scaling.
- Store sensitive data securely using environment secrets and managed identities.
- Use revision-based traffic routing for safe rollouts and A/B testing.
- Place apps in virtual networks to manage traffic flow and access control.
- Monitor job runs and define retry and timeout settings for reliability.
- Validate your Terraform configuration to ensure proper deployment of container resources.

## License
This module is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
<!-- END OF PRE-COMMIT-OPENTOFU DOCS HOOK -->