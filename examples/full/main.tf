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
  source = "git@ssh.dev.azure.com:v3/DevOpsCloudAstro/ca-terraform-modules/azure//tf-azurerm-container-app-environment"

  name                = "ca-env-dev"
  location            = azurerm_resource_group.ca-rg.location
  resource_group_name = azurerm_resource_group.ca-rg.name
  workload_profile = [
    {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }
  ]
}

##### Container Apps Example #####

module "container_app" {
  source = "../../"

  container_type               = "app"
  name                         = "example-container-app"
  resource_group_name          = azurerm_resource_group.ca-rg.name
  container_app_environment_id = module.ca-environment.resource.id
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
  container_app_environment_id = module.ca-environment.resource.id
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
