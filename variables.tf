variable "container_type" {
  type        = string
  default     = "app"
  description = <<DESCRIPTION
  * `container_type` - (Required) Container Type must be either `app` or `job`, default value is `app`.

  Example Input:
  ```
  container_type = "app"
  ```
  DESCRIPTION
  validation {
    condition     = var.container_type == null || var.container_type == "app" || var.container_type == "job"
    error_message = "container_type must be either 'app' or 'job'."
  }
}

variable "container_app_environment_id" {
  type        = string
  description = <<DESCRIPTION
  * `container_app_environment_id` - (Required) The ID of the Container App Environment within which this Container App/Job should exist. Changing this forces a new resource to be created.

  Example Input:
  ```
  container_app_environment_id = "/subscriptions/<subscription_id>/resourceGroups/myResourceGroup/providers/Microsoft.App/containerApps/myContainerAppEnvironment"
  ```
  DESCRIPTION
}

variable "name" {
  type        = string
  description = <<DESCRIPTION
  * `name` - (Required) The name for this Container App/Job. Changing this forces a new resource to be created.

  Example Input:
  ```
  name = "my-container"
  ```
  DESCRIPTION
}

variable "resource_group_name" {
  type        = string
  description = <<DESCRIPTION
  * `resource_group_name` - (Required) The name of the resource group in which the Container App Environment is to be created. Changing this forces a new resource to be created.

  Example Input:
  ```
  resource_group_name = "myResourceGroup"
  ```
  DESCRIPTION

}

variable "location" {
  type        = string
  default     = null
  description = <<DESCRIPTION
  * `location` - (Required) Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.

  ~> **Note:** For Container Apps, the location is the same as the Environment in which it is deployed.

  Example Input:
  ```
  name = "germanywestcetnral"
  ```
  DESCRIPTION
}

variable "template" {
  type = object({
    init_container = optional(map(object({
      args              = optional(list(string))
      command           = optional(list(string))
      cpu               = optional(number)
      ephemeral_storage = optional(string)
      image             = string
      memory            = optional(string)
      name              = string
      env = optional(list(object({
        name        = string
        secret_name = optional(string)
        value       = optional(string)
      })))
      volume_mounts = optional(list(object({
        name     = string
        path     = string
        sub_path = optional(string)
      })))
    })))
    container = map(object({
      args              = optional(list(string))
      command           = optional(list(string))
      cpu               = number
      ephemeral_storage = optional(string)
      image             = string
      memory            = string
      name              = string
      env = optional(list(object({
        name        = string
        secret_name = optional(string)
        value       = optional(string)
      })))
      liveness_probe = optional(list(object({
        failure_count_threshold = optional(number, 3)
        header = optional(list(object({
          name  = string
          value = string
        })))
        host             = optional(string)
        initial_delay    = optional(number, 1)
        interval_seconds = optional(number, 10)
        path             = optional(string, "/")
        port             = number
        timeout          = optional(number, 1)
        transport        = string
      })))
      readiness_probe = optional(list(object({
        failure_count_threshold = optional(number, 3)
        header = optional(list(object({
          name  = string
          value = string
        })))
        host                    = optional(string)
        initial_delay           = optional(number, 0)
        interval_seconds        = optional(number, 10)
        path                    = optional(string, "/")
        port                    = number
        success_count_threshold = optional(number, 3)
        timeout                 = optional(number, 1)
        transport               = string
      })))
      startup_probe = optional(list(object({
        failure_count_threshold = optional(number, 3)
        header = optional(list(object({
          name  = string
          value = string
        })))
        host             = optional(string)
        initial_delay    = optional(number, 0)
        interval_seconds = optional(number, 10)
        path             = optional(string, "/")
        port             = number
        timeout          = optional(number, 1)
        transport        = string
      })))
      volume_mounts = optional(list(object({
        name     = string
        path     = string
        sub_path = optional(string)
      })))
    }))
    max_replicas = optional(number)
    min_replicas = optional(number)
    azure_queue_scale_rules = optional(list(object({
      name         = string
      queue_name   = string
      queue_length = number
      authentication = list(object({
        secret_name       = string
        trigger_parameter = string
      }))
    })))
    custom_scale_rules = optional(list(object({
      name             = string
      custom_rule_type = string
      metadata         = map(string)
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })))
    })))
    http_scale_rules = optional(list(object({
      name                = string
      concurrent_requests = string
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = optional(string)
      })))
    })))
    tcp_scale_rules = optional(list(object({
      name                = string
      concurrent_requests = string
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = optional(string)
      })))
    })))
    revision_suffix                  = optional(string)
    termination_grace_period_seconds = optional(number)
    volume = optional(list(object({
      name          = string
      storage_name  = optional(string)
      storage_type  = optional(string, "EmptyDir")
      mount_options = optional(string)
    })))
  })
  description = <<DESCRIPTION
   * `template` - (Required) A `template` block as detailed below.
    * `init_container` - (Optional) The definition of an init container that is part of the group as documented in the `init_container` block below.
      * `args` - (Optional) A list of extra arguments to pass to the container.
      * `command` - (Optional) A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
      * `cpu` - (Optional) The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.

      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.0` / `2.0` or `0.5` / `1.0`
      * `env` - (Optional) One or more `env` blocks as detailed below.
        * `name` - (Required) The name of the environment variable for the container.
        * `secret_name` - (Optional) The name of the secret that contains the value for this environment variable.
        * `value` - (Optional) The value for this environment variable.

        ~> **Note:** This value is ignored if `secret_name` is used
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.

      ~> **Note:** `ephemeral_storage` is currently in preview and not configurable at this time.
      * `image` - (Required) The image to use to create the container.
      * `memory` - (Optional) The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.

      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.25` / `2.5Gi` or `0.75` / `1.5Gi`
      * `name` - (Required) The name of the container
      * `volume_mounts` - (Optional) A `volume_mounts` block as detailed below.
        * `name` - (Required) The name of the Volume to be mounted in the container.
        * `path` - (Required) The path in the container at which to mount this volume.
        * `sub_path` - (Optional) The sub path of the volume to be mounted in the container.
    * `container` - (Required) One or more `container` blocks as detailed below.
      * `args` - (Optional) A list of extra arguments to pass to the container.
      * `command` - (Optional) A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
      * `cpu` - (Required) The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.

      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.0` / `2.0` or `0.5` / `1.0`
      * `env` - (Optional) One or more `env` blocks as detailed below.
        * `name` - (Required) The name of the environment variable for the container.
        * `secret_name` - (Optional) The name of the secret that contains the value for this environment variable.
        * `value` - (Optional) The value for this environment variable.

        ~> **Note:** This value is ignored if `secret_name` is used
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.

      ~> **Note:** `ephemeral_storage` is currently in preview and not configurable at this time.
      * `image` - (Required) The image to use to create the container.
      * `memory` - (Required) The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.
      * `name` - (Required) The name of the container
      * `liveness_probe` - (Optional) A `liveness_probe` block as detailed below.
        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.
        * `header` - (Optional) A `header` block as detailed below.
          * `name` - (Required) The HTTP Header Name.
          * `value` - (Required) The HTTP Header value.
        * `host` - (Optional) The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.
        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.
        * `path` - (Optional) The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.


      ~> **Note:** `cpu` and `memory` must be specified in `0.25'/'0.5Gi` combination increments. e.g. `1.25` / `2.5Gi` or `0.75` / `1.5Gi`
      * `readiness_probe` - (Optional) A `readiness_probe` block as detailed below.
        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - (Optional) A `header` block as detailed below.
          * `name` - (Required) The HTTP Header Name.
          * `value` - (Required) The HTTP Header value.
        * `host` - (Optional) The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - (Optional) The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.
        * `success_count_threshold` - (Optional) The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.
        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
      * `startup_probe` - (Optional) A `startup_probe` block as detailed below.
        * `failure_count_threshold` - (Optional) The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - (Optional) A `header` block as detailed below.
          * `name` - (Required) The HTTP Header Name.
          * `value` - (Required) The HTTP Header value.
        * `host` - (Optional) The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - (Optional) The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - (Optional) How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - (Optional) The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - (Required) The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - (Optional) Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - (Required) Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
        * `volume_mounts` - (Optional) A `volume_mounts` block as detailed below.
          * `name` - (Required) The name of the Volume to be mounted in the container.
          * `path` - (Required) The path in the container at which to mount this volume.
          * `sub_path` - (Optional) The sub path of the volume to be mounted in the container.
    * `max_replicas` - (Optional) The maximum number of replicas for this container.
    * `min_replicas` - (Optional) The minimum number of replicas for this container.
    * `azure_queue_scale_rule` - (Optional) One or more `azure_queue_scale_rule` blocks as defined below.
      * `name` - (Required) The name of the Scaling Rule
      * `queue_name` - (Required) The name of the Azure Queue
      * `queue_length` - (Required) The value of the length of the queue to trigger scaling actions.
      * `authentication` - (Required) One or more `authentication` blocks as defined below.
        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
    * `custom_scale_rule` - (Optional) One or more `custom_scale_rule` blocks as defined below.
      * `name` - (Required) The name of the Scaling Rule
      * `custom_rule_type` - (Required) The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.
      * `metadata` - (Required) - A map of string key-value pairs to configure the Custom Scale Rule.
      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.
        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
    * `http_scale_rule` - (Optional) One or more `http_scale_rule` blocks as defined below.
      * `name` - (Required) The name of the Scaling Rule
      * `concurrent_requests` - (Required) - The number of concurrent requests to trigger scaling.
      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.
        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
    * `tcp_scale_rule` - (Optional) One or more `tcp_scale_rule` blocks as defined below.
      * `name` - (Required) The name of the Scaling Rule
      * `concurrent_requests` - (Required) - The number of concurrent requests to trigger scaling.
      * `authentication` - (Optional) Zero or more `authentication` blocks as defined below.
        * `secret_name` - (Required) The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - (Required) The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
    * `revision_suffix` - (Optional) The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.
    * `termination_grace_period_seconds` - (Optional) The time in seconds after the container is sent the termination signal before the process if forcibly killed.
    * `volume` - (Optional) A `volume` block as detailed below.
      * `name` - (Required) The name of the volume.
      * `storage_name` - (Optional) The name of the `AzureFile` storage.
      * `storage_type` - (Optional) The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.

  Example Input:
  ```
  template = {
  init_container = [
    {
      name = "init-container-1"
      image = "nginx:1.21"
      cpu = 0.25
      memory = "0.5Gi"
      args = ["--debug"]
      command = ["/bin/sh", "-c"]
      env = [
        {
          name = "ENV_VAR_1"
          value = "value1"
        },
        {
          name = "SECRET_ENV_VAR"
          secret_name = "my-secret"
        }
      ]
      volume_mounts = [
        {
          name = "init-volume"
          path = "/init-data"
        }
      ]
    }
  ]
  container = [
    {
      name = "app-container"
      image = "myapp:latest"
      cpu = 1.0
      memory = "2Gi"
      args = ["--start"]
      command = ["/app/entrypoint.sh"]
      env = [
        {
          name = "APP_ENV"
          value = "production"
        }
      ]
      liveness_probe = [
        {
          port = 8080
          path = "/healthz"
          interval_seconds = 10
          timeout = 5
          transport = "HTTP"
        }
      ]
      readiness_probe = [
        {
          port = 8080
          path = "/ready"
          interval_seconds = 10
          success_count_threshold = 1
          transport = "HTTP"
        }
      ]
      startup_probe = [
        {
          port = 8080
          path = "/start"
          interval_seconds = 5
          timeout = 3
          transport = "HTTP"
        }
      ]
      volume_mounts = [
        {
          name = "app-volume"
          path = "/data"
        }
      ]
    }
  ]
  max_replicas = 5
  min_replicas = 1
  revision_suffix = "v1"
  termination_grace_period_seconds = 30
  azure_queue_scale_rules = [
    {
      name = "queue-scale-rule"
      queue_length = 100
      queue_name = "my-queue"
      authentication = [
        {
          secret_name = "queue-auth-secret"
          trigger_parameter = "queueConnectionString"
        }
      ]
    }
  ]
  custom_scale_rules = [
    {
      name = "custom-rule"
      custom_rule_type = "cpu"
      metadata = {
        threshold = "75"
        period = "1m"
      }
      authentication = [
        {
          secret_name = "custom-auth-secret"
          trigger_parameter = "customConnectionString"
        }
      ]
    }
  ]
  http_scale_rules = [
    {
      name = "http-scale-rule"
      concurrent_requests = "100"
      authentication = [
        {
          secret_name = "http-auth-secret"
        }
      ]
    }
  ]
  volume = [
    {
      name = "app-volume"
      storage_name = "my-storage"
      storage_type = "AzureFile"
    }
  ]
 }
 ```
  DESCRIPTION
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
  description = <<DESCRIPTION
  * `identity` - (Optional) An `identity` block as detailed below.
    * `system_assigned` - (Required) The type of managed identity to assign. Possible values are `SystemAssigned`, `UserAssigned`, and `SystemAssigned, UserAssigned` (to enable both).
    * `identity_ids` - (Optional) - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`.

  Example Inputs:
  ```
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/my-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/my-identity"
  }
  ```
  DESCRIPTION
}

variable "registry" {
  type = map(object({
    server               = string
    identity             = optional(string)
    password_secret_name = optional(string)
    username             = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
  * `registries` - (Optional) A `template` block as detailed below.
    * `server` - (Required) The hostname for the Container Registry.
    The authentication details must also be supplied, `identity` and `username`/`password_secret_name` are mutually exclusive.
    * `identity` - (Optional) Resource ID for the User Assigned Managed identity to use when pulling from the Container Registry.

    ~> **Note:** The Resource ID must be of a User Assigned Managed identity defined in an `identity` block.
    * `password_secret_name` - (Optional) The name of the Secret Reference containing the password value for this user on the Container Registry, `username` must also be supplied.
    * `username` - (Optional) The username to use for this Container Registry, `password_secret_name` must also be supplied..

  Example Input:
  ```
  registries = {
    registry1 = {
    server               = "mycontainerregistry.azurecr.io"
    username             = "myregistryuser"
    password_secret_name = "myregistrysecret"
    },
    registry2 = {
    server   = "anotherregistry.azurecr.io"
    identity = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myIdentity"
    }
  }
  ```
  DESCRIPTION
}

variable "secret" {
  type = map(object({
    name                = string
    identity            = optional(string)
    key_vault_secret_id = optional(string)
    value               = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
  * `secrets` - (Optional) A `secrets` block as detailed below.
    * `name` - (Required) The secret name.
    * `identity` - (Optional) The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.

    ~> **Note:** `identity` must be used together with `key_vault_secret_id`
    * `key_vault_secret_id` - (Optional) The ID of a Key Vault secret. This can be a versioned or version-less ID.

    ~> **Note:** When using `key_vault_secret_id`, `ignore_changes` should be used to ignore any changes to `value`.
    * `value` - (Optional) The value for this secret.

    ~> **Note:** `value` will be ignored if `key_vault_secret_id` and `identity` are provided.

  Example Input:
  ```
  secrets = {
  "db_password" = {
    identity            = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myIdentity"
    key_vault_secret_id = "/subscriptions/xxxxxx/resourceGroups/myResourceGroup/providers/Microsoft.KeyVault/vaults/myKeyVault/secrets/dbPassword"
    name                = "db_password"
  },
  "api_key" = {
    name  = "api_key"
    value = "s3cr3tAPIkey123"
  },
  "system_secret" = {
    identity = "System"
    name     = "system_secret_name"
  }
 }
  ```
  DESCRIPTION
}

variable "workload_profile_name" {
  type        = string
  default     = null
  description = <<DESCRIPTION
  * `workload_profile_name` - (Optional) The name of the Workload Profile in the Container App Environment to place this Container App/Job.

  Example Input:
  ```
  workload_profile_name = "standard-workload-profile"
  ```
  DESCRIPTION
}

variable "timeouts" {
  type = object({
    create = optional(string, "30")
    delete = optional(string, "5")
    read   = optional(string, "30")
    update = optional(string, "30")
  })
  default     = null
  description = <<DESCRIPTION
  * `timeouts` block as detailed below.
    * `create` - (Defaults to 30 minutes) Used when creating the Container App/Job.
    * `delete` - (Defaults to 30 minutes) Used when deleting the Container App/Job.
    * `read` - (Defaults to 5 minutes) Used when retrieving the Container App/Job.
    * `update` - (Defaults to 30 minutes) Used when updating the Container App/Job.

  Example Input:
  ```
  container_app_timeouts = {
    create = "45m"
    delete = "30m"
    read   = "10m"
    update = "40m"
  }
  ```
  DESCRIPTION
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string)
  })
  default     = null
  description = <<DESCRIPTION
  * `lock` block as detailed below.
    * `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    * `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

  Example Input:
  ```
  lock = {
    kind = "CanNotDelete"
    name = "my-resource-lock"
  }
  ```
  DESCRIPTION
  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "role_assignment" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string)
    condition_version                      = optional(string)
    delegated_managed_identity_resource_id = optional(string)
    principal_type                         = optional(string)
  }))
  default     = null
  description = <<DESCRIPTION
  * `role_assignment` block as detailed below.
    * `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    * `principal_id` - The ID of the principal to assign the role to.
    * `description` - (Optional) The description of the role assignment.
    * `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    * `condition` - (Optional) The condition which will be used to scope the role assignment.
    * `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
    * `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
    * `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

  ~> **Note:** only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

  Example Input:
  ```
  role_assignments = {
  "assignment1" = {
    role_definition_id_or_name             = "Contributor"
    principal_id                           = "11111111-2222-3333-4444-555555555555"
    description                            = "Granting contributor access"
    skip_service_principal_aad_check       = false
    principal_type                         = "User"
  },
  "assignment2" = {
    role_definition_id_or_name             = "Reader"
    principal_id                           = "66666666-7777-8888-9999-000000000000"
    skip_service_principal_aad_check       = true
    principal_type                         = "ServicePrincipal"
  }
 }
  ```
  DESCRIPTION
}

variable "tags" {
  type        = map(string)
  default     = null
  description = <<DESCRIPTION
  * `tags` - (Optional) A map of tags to associate with the network and subnets.

  Example Input:
  ```
  tags = {
    "environment" = "production"
    "department"  = "IT"
  }
  ```
  DESCRIPTION
}

######## CONTAINER APP VARS #########

variable "revision_mode" {
  type        = string
  description = <<DESCRIPTION
  * `revision_mode` - (Required) The revisions operational mode for the Container App. Possible values include `Single` and `Multiple`. In `Single` mode, a single revision is in operation at any given time. In `Multiple` mode, more than one revision can be active at a time and can be configured with load distribution via the `traffic_weight` block in the `ingress` configuration.

  ~> **Note:** This variable is used only for container apps.

  Example Input:
  ```
  revision_mode = "Single"
  ```
  DESCRIPTION
}

variable "dapr" {
  type = object({
    app_id       = string
    app_port     = optional(number)
    app_protocol = optional(string, "http")
  })
  default     = null
  description = <<DESCRIPTION
  * `dapr` - (Optional) A `dapr` block as detailed below.
    * `app_id` - (Required) The Dapr Application Identifier.
    * `app_port` - (Optional) The port which the application is listening on. This is the same as the `ingress` port.
    * `app_protocol` - (Optional) The protocol for the app. Possible values include `http` and `grpc`. Defaults to `http`.

  Example Input:
  ```
  dapr = {
  app_id       = "my-dapr-app"
  app_port     = 5000
  app_protocol = "http"
  }
  ```
  DESCRIPTION
}

variable "ingress" {
  type = object({
    allow_insecure_connections = optional(bool)
    external_enabled           = optional(bool, false)
    fqdn                       = optional(string)
    cors = optional(object({
      allowed_origins           = optional(list(string))
      allow_credentials_enabled = optional(bool, false)
      allowed_headers           = optional(list(string))
      allowed_methods           = optional(list(string))
      exposed_headers           = optional(list(string))
      max_age_in_seconds        = optional(number)
    }))
    ip_security_restriction = optional(list(object({
      action           = string
      description      = optional(string)
      ip_address_range = string
      name             = string
    })))
    target_port  = number
    exposed_port = optional(number)
    traffic_weight = list(object({
      label           = optional(string)
      latest_revision = optional(bool)
      revision_suffix = optional(string)
      percentage      = number
    }))
    transport               = optional(string, "auto")
    client_certificate_mode = optional(string)
    custom_domain = optional(object({
      certificate_binding_type = optional(string)
      certificate_id           = string
      name                     = string
    }))
  })
  default     = null
  description = <<DESCRIPTION
  * `ingress` - (Optional) An `ingress` block as detailed below.
    * `allow_insecure_connections` - (Optional) Should this ingress allow insecure connections?
    * `cors` - (Optional) A `cors` block as defined below.
      * `allowed_origins` - (Required) Specifies the list of origins that are allowed to make cross-origin calls.
      * `allow_credentials_enabled` - (Optional) Whether user credentials are allowed in the cross-origin request is enabled. Defaults to `false`.
      * `allowed_headers` - (Optional) Specifies the list of request headers that are permitted in the actual request.
      * `allowed_methods` - (Optional) Specifies the list of HTTP methods are allowed when accessing the resource in a cross-origin request.
      * `exposed_headers` - (Optional) Specifies the list of headers exposed to the browser in the response to a cross-origin request.
      * `max_age_in_seconds` - (Optional) Specifies the number of seconds that the browser can cache the results of a preflight request.
    * `fqdn` - The FQDN of the ingress.
    * `external_enabled` - (Optional) Are connections to this Ingress from outside the Container App Environment enabled? Defaults to `false`.
    * `ip_security_restriction` - (Optional) One or more `ip_security_restriction` blocks for IP-filtering rules as defined below.
      * `action` - (Required) The IP-filter action. `Allow` or `Deny`.

      ~> **Note:** The `action` types in an all `ip_security_restriction` blocks must be the same for the `ingress`, mixing `Allow` and `Deny` rules is not currently supported by the service.
      * `description` - (Optional) Describe the IP restriction rule that is being sent to the container-app.
      * `ip_address_range` - (Required) The incoming IP address or range of IP addresses (in CIDR notation).
      * `name` - (Required) Name for the IP restriction rule.
    * `target_port` - (Required) The target port on the container for the Ingress traffic.
    * `exposed_port` - (Optional) The exposed port on the container for the Ingress traffic.

    ~> **Note:** `exposed_port` can only be specified when `transport` is set to `tcp`.
    * `traffic_weight` - (Required) One or more `traffic_weight` blocks as detailed below.

      ~> **Note:** This block only applies when `revision_mode` is set to `Multiple`.
      * `label` - (Optional) The label to apply to the revision as a name prefix for routing traffic.
      * `latest_revision` - (Optional) This traffic Weight applies to the latest stable Container Revision. At most only one `traffic_weight` block can have the `latest_revision` set to `true`.
      * `revision_suffix` - (Optional) The suffix string to which this `traffic_weight` applies.

      ~> **Note:** If `latest_revision` is `false`, the `revision_suffix` shall be specified.
      * `percentage` - (Required) The percentage of traffic which should be sent this revision.

      ~> **Note:** The cumulative values for `weight` must equal 100 exactly and explicitly, no default weights are assumed.
    * `transport` - (Optional) The transport method for the Ingress. Possible values are `auto`, `http`, `http2` and `tcp`. Defaults to `auto`.

    ~> **Note:**  if `transport` is set to `tcp`, `exposed_port` and `target_port` should be set at the same time.
    * `client_certificate_mode` - (Optional) The client certificate mode for the Ingress. Possible values are `require`, `accept`, and `ignore`.

  Example Input:
  ```
  ingress = {
    ingress1 = {
  allow_insecure_connections = false
  fqdn                       = "app.example.com"
  cors = {
    allowed_origins           = ["https://example.com", "https://app.example.com"]
    allow_credentials_enabled = true
    allowed_headers           = ["Content-Type", "Authorization"]
    allowed_methods           = ["GET", "POST", "OPTIONS"]
    exposed_headers           = ["X-Custom-Header"]
    max_age_in_seconds        = 3600
  }
  external_enabled           = true
  target_port                = 8080
  exposed_port               = 80
  transport                  = "http"
  client_certificate_mode = "accept"
  custom_domain = {
    certificate_binding_type = "SNI"
    certificate_id           = "cert-12345"
    name                     = "custom.example.com"
  }
  ip_security_restriction = [
    {
      action           = "Allow"
      description      = "Allow traffic from internal network"
      ip_address_range = "10.0.0.0/24"
      name             = "internal-allow"
    },
    {
      action           = "Deny"
      description      = "Block traffic from specific IP range"
      ip_address_range = "192.168.1.0/24"
      name             = "restricted-block"
    }
  ]
  traffic_weight = [
    {
      label           = "v1"
      latest_revision = false
      revision_suffix = "rev1"
      percentage      = 50
    },
    {
      label           = "v2"
      latest_revision = true
      percentage      = 50
    }
   ]
   }
  }
  ```
  DESCRIPTION
}

###### CONTAINER JOB VARS ######

variable "replica_timeout_in_seconds" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  * `replica_timeout_in_seconds` - (Required) The maximum number of seconds a replica is allowed to run.

  ~> **Note:** This variable is used only for container job.

  Example Input:
  ```
  replica_timeout_in_seconds = 3600
  ```
  DESCRIPTION
}

variable "replica_retry_limit" {
  type        = number
  default     = null
  description = <<DESCRIPTION
  * `replica_retry_limit` - (Optional) The maximum number of times a replica is allowed to retry.

  ~> **Note:** This variable is used only for container job.

  Example Input:
  ```
  replica_retry_limit = 5
  ```
  DESCRIPTION
}

variable "manual_trigger_config" {
  type = object({
    parallelism              = optional(number)
    replica_completion_count = optional(number)
  })
  default     = null
  description = <<DESCRIPTION
  * `manual_trigger_config` - (Optional) A `manual_trigger_config` block as defined below.
    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.
    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.

  ~> **Note:** This variable is used only for container job.

  Example Input:
  ```
  manual_trigger_config = {
    parallelism              = 5
    replica_completion_count = 3
  }
  ```
  DESCRIPTION
}

variable "event_trigger_config" {
  type = list(object({
    parallelism              = optional(number)
    replica_completion_count = optional(number)
    scale = map(object({
      max_executions              = optional(number)
      min_executions              = optional(number)
      polling_interval_in_seconds = optional(number)
      rules = map(object({
        name             = optional(string)
        custom_rule_type = optional(string)
        metadata         = map(string)
        authentication = map(object({
          secret_name       = optional(string)
          trigger_parameter = optional(string)
        }))
      }))
    }))
  }))
  default     = null
  description = <<DESCRIPTION
  * `event_trigger_config` - (Optional) A `event_trigger_config` block as defined below.
    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.
    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.
    * `scale` - (Optional) A `scale` block as defined below.
      * `max_executions` - (Optional) Maximum number of job executions that are created for a trigger.
      * `min_executions` - (Optional) Minimum number of job executions that are created for a trigger.
      * `polling_interval_in_seconds` - (Optional) Interval to check each event source in seconds.
      * `rules` - (Optional) A `rules` block as defined below.
        * `name` - (Optional) Name of the scale rule.
        * `custom_rule_type` - (Optional) Type of the scale rule.
        * `metadata` - (Optional) Metadata properties to describe the scale rule.
        * `authentication` - (Optional) A `authentication` block as defined below.
          * `secret_name` - (Optional) Name of the secret from which to pull the auth params.
          * `trigger_parameter` - (Optional) Trigger Parameter that uses the secret.

  ~> **Note:** This variable is used only for container job.

  Example Input:
  ```
  event_trigger_config = [
    {
      parallelism              = 2
      replica_completion_count = 1
      scale = {
        my_scale_rule = {
          max_executions              = 5
          min_executions              = 1
          polling_interval_in_seconds = 30
          rules = {
            my_rule = {
              name             = "queue-scale-rule"
              custom_rule_type = "azure-queue"
              metadata = {
                queueName   = "my-queue"
                queueLength = "5"
              }
              authentication = {
                auth1 = {
                  secret_name       = "azure-storage-secret"
                  trigger_parameter = "connection"
                }
              }
            }
          }
        }
      }
    }
  ]
  ```
  DESCRIPTION
}

variable "schedule_trigger_config" {
  type = list(object({
    cron_expression          = string
    parallelism              = optional(number)
    replica_completion_count = optional(number)
  }))
  default     = null
  description = <<DESCRIPTION
  * `schedule_trigger_config` - (Optional) A `schedule_trigger_config` block as defined below.

  ~> **Note:** Only one of `manual_trigger_config`, `event_trigger_config` or `schedule_trigger_config` can be specified.
    * `cron_expression` - (Required) Cron formatted repeating schedule of a Cron Job.
    * `parallelism` - (Optional) Number of parallel replicas of a job that can run at a given time.
    * `replica_completion_count` - (Optional) Minimum number of successful replica completions before overall job completion.

  ~> **Note:** This variable is used only for container job.

  Example Input:
  ```
  schedule_trigger_config = [
    {
      cron_expression          = "0 0 * * *"
      parallelism              = 5
      replica_completion_count = 3
    }
  ]
  ```
  DESCRIPTION
}
