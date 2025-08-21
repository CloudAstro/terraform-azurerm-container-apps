output "container_app" {
  value       = azurerm_container_app.this
  description = <<DESCRIPTION
    * `container_app_environment_id` - The ID of the Container App Environment this Container App is linked to.
    * `name` - The name of the Container App.
    * `resource_group_name` - The name of the Resource Group where this Container App exists.
    * `revision_mode` - The revision mode of the Container App.
    * `workload_profile_name` - The name of the Workload Profile in the Container App Environment in which this Container App is running.
    * `tags` - A mapping of tags to assign to the Container App.

    A `template` block exports the following:
      * `init_container` -  One or more `init_container` blocks detailed below.
      * `args` - A list of extra arguments to pass to the container.
      * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
      * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`.
      * `env` - One or more `env` blocks as detailed below.
        * `name` - The name of the environment variable for the container.
        * `secret_name` - The name of the secret that contains the value for this environment variable.
        * `value` - The value for this environment variable.
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App.
      * `image` - The image to use to create the container.
      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`.
      * `name` - The name of the container
      * `volume_mounts` - A `volume_mounts` block as detailed below.
        * `name` - The name of the Volume to be mounted in the container.
        * `path` - The path in the container at which to mount this volume.
        * `sub_path` - The sub path of the volume to be mounted in the container.
      * `container` - One or more `container` blocks as detailed below.
        * `args` - A list of extra arguments to pass to the container.
        * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
        * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`.
      * `env` - One or more `env` blocks as detailed below.
        * `name` - The name of the environment variable for the container.
        * `secret_name` - The name of the secret that contains the value for this environment variable.
        * `value` - The value for this environment variable.
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App.
      * `image` - The image to use to create the container.
      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`.
      * `name` - The name of the container
      * `liveness_probe` - A `liveness_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.
        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
      * `readiness_probe` - A `readiness_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.
        * `success_count_threshold` - The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
      * `startup_probe` - A `startup_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
        * `volume_mounts` - A `volume_mounts` block as detailed below.
          * `name` - The name of the Volume to be mounted in the container.
          * `path` - The path in the container at which to mount this volume.
          * `sub_path` - The sub path of the volume to be mounted in the container.
      * `max_replicas` - The maximum number of replicas for this container.
      * `min_replicas` - The minimum number of replicas for this container.
      * `azure_queue_scale_rule` - One or more `azure_queue_scale_rule` blocks as defined below.
      * `name` - The name of the Scaling Rule
      * `queue_name` - The name of the Azure Queue
      * `queue_length` - The value of the length of the queue to trigger scaling actions.
      * `authentication` - One or more `authentication` blocks as defined below.
        * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `custom_scale_rule` - One or more `custom_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `custom_rule_type` - The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.
        * `metadata` -  A map of string key-value pairs to configure the Custom Scale Rule.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `http_scale_rule` - One or more `http_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `concurrent_requests` - The number of concurrent requests to trigger scaling.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `tcp_scale_rule` - One or more `tcp_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `concurrent_requests` - The number of concurrent requests to trigger scaling.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `revision_suffix` - The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.
      * `termination_grace_period_seconds` - The time in seconds after the container is sent the termination signal before the process if forcibly killed.
      * `volume` - A `volume` block as detailed below.
        * `name` - The name of the volume.
        * `storage_name` - The name of the `AzureFile` storage.
        * `storage_type` - The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.

    An `identity` block supports the following:
        * `type` - The type of managed identity to assign. Possible values are UserAssigned and SystemAssigned
        * `identity_ids` - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when type is set to UserAssigned.

    A `secrets` block supports the following:
        * `name` - The secret name.
        * `identity` - The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.
        * `key_vault_secret_id` - The ID of a Key Vault secret. This can be a versioned or version-less ID.
        * `value` - The value for this secret.

    An `ingress` block supports the following:
        * `allow_insecure_connections` - Should this ingress allow insecure connections?
        * `cors` - A `cors` block as defined below.
            * `allowed_origins` - Specifies the list of origins that are allowed to make cross-origin calls.
            * `allow_credentials_enabled` - Whether user credentials are allowed in the cross-origin request is enabled. Defaults to `false`.
            * `allowed_headers` - Specifies the list of request headers that are permitted in the actual request.
            * `allowed_methods` - Specifies the list of HTTP methods are allowed when accessing the resource in a cross-origin request.
            * `exposed_headers` - Specifies the list of headers exposed to the browser in the response to a cross-origin request.
            * `max_age_in_seconds` - Specifies the number of seconds that the browser can cache the results of a preflight request.
        * `fqdn` - The FQDN of the ingress.
        * `external_enabled` - Are connections to this Ingress from outside the Container App Environment enabled? Defaults to `false`.
        * `ip_security_restriction` - One or more `ip_security_restriction` blocks for IP-filtering rules as defined below.
            * `action` - The IP-filter action. `Allow` or `Deny`.
        * `description` - Describe the IP restriction rule that is being sent to the container-app.
        * `ip_address_range` - The incoming IP address or range of IP addresses (in CIDR notation).
        * `name` - Name for the IP restriction rule.
        * `target_port` - The target port on the container for the Ingress traffic.
        * `exposed_port` - The exposed port on the container for the Ingress traffic.
        * `traffic_weight` - One or more `traffic_weight` blocks as detailed below.
        * `label` - The label to apply to the revision as a name prefix for routing traffic.
        * `latest_revision` - This traffic Weight applies to the latest stable Container Revision. At most only one `traffic_weight` block can have the `latest_revision` set to `true`.
        * `revision_suffix` - The suffix string to which this `traffic_weight` applies.
        * `percentage` -  The percentage of traffic which should be sent this revision.
        * `transport` - The transport method for the Ingress. Possible values are `auto`, `http`, `http2` and `tcp`. Defaults to `auto`.
        * `client_certificate_mode` - The client certificate mode for the Ingress. Possible values are `require`, `accept`, and `ignore`.

    A `dapr` block supports the following:
        * `app_id` - The Dapr Application Identifier.
        * `app_port` - The port which the application is listening on. This is the same as the `ingress` port.
        * `app_protocol` - The protocol for the app. Possible values include `http` and `grpc`. Defaults to `http`.

    A `registry` block supports the following:
        * `server` - The hostname for the Container Registry.
        * `username` - The username to use for this Container Registry, `password_secret_name` must also be supplied..
        * `password_secret_name` - The name of the Secret Reference containing the password value for this user on the Container Registry, username must also be supplied.
        * `identity` - Resource ID for the User Assigned Managed identity to use when pulling from the Container Registry.

  Example output:
  ```
  output "name" {
    value = module.module_name.container_app.name
  }
  ```
  DESCRIPTION
}

output "container_job" {
  value       = azurerm_container_app_job.this
  description = <<DESCRIPTION
   * `name` - Specifies the name of the Container App Job. Changing this forces a new resource to be created.
   * `resource_group_name` - The name of the resource group in which to create the resource. Changing this forces a new resource to be created.
   * `location` - Specifies the supported Azure location where the resource exists. Changing this forces a new resource to be created.
   * `environment_id` - The ID of the Container Apps Environment in which to create the Container App Job. Changing this forces a new resource to be created.
   * `replica_timeout_in_seconds` - The maximum number of seconds a replica is allowed to run.
   * `workload_profile_name` - The name of the workload profile to use for the Container App Job.
   * `replica_retry_limit` - The maximum number of times a replica is allowed to retry.
   * `tags` - A mapping of tags to assign to the resource.

    A `template` block supports the following:
      * `init_container` - The definition of an init container that is part of the group as documented in the `init_container` block below.
      * `args` - A list of extra arguments to pass to the container.
      * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
      * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.
      * `env` - One or more `env` blocks as detailed below.
        * `name` - The name of the environment variable for the container.
        * `secret_name` - The name of the secret that contains the value for this environment variable.
        * `value` - The value for this environment variable.
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.
      * `image` - The image to use to create the container.
      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.
      * `name` - The name of the container
      * `volume_mounts` - A `volume_mounts` block as detailed below.
        * `name` - The name of the Volume to be mounted in the container.
        * `path` - The path in the container at which to mount this volume.
        * `sub_path` - The sub path of the volume to be mounted in the container.
      * `container` - One or more `container` blocks as detailed below.
        * `args` - A list of extra arguments to pass to the container.
        * `command` - A command to pass to the container to override the default. This is provided as a list of command line elements without spaces.
        * `cpu` - The amount of vCPU to allocate to the container. Possible values include `0.25`, `0.5`, `0.75`, `1.0`, `1.25`, `1.5`, `1.75`, and `2.0`. When there's a workload profile specified, there's no such constraint.
      * `env` - One or more `env` blocks as detailed below.
        * `name` - The name of the environment variable for the container.
        * `secret_name` - The name of the secret that contains the value for this environment variable.
        * `value` - The value for this environment variable.
      * `ephemeral_storage` - The amount of ephemeral storage available to the Container App/Job.
      * `image` - The image to use to create the container.
      * `memory` - The amount of memory to allocate to the container. Possible values are `0.5Gi`, `1Gi`, `1.5Gi`, `2Gi`, `2.5Gi`, `3Gi`, `3.5Gi` and `4Gi`. When there's a workload profile specified, there's no such constraint.
      * `name` - The name of the container
      * `liveness_probe` - A `liveness_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `10`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `1` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are in the range `1` - `240`. Defaults to `10`.
        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` -  The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
      * `readiness_probe` - A `readiness_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The probe hostname. Defaults to the pod IP address. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - The URI to use for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.
        * `success_count_threshold` - The number of consecutive successful responses required to consider this probe as successful. Possible values are between `1` and `10`. Defaults to `3`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
      * `startup_probe` - A `startup_probe` block as detailed below.
        * `failure_count_threshold` - The number of consecutive failures required to consider this probe as failed. Possible values are between `1` and `30`. Defaults to `3`.
        * `header` - A `header` block as detailed below.
          * `name` - The HTTP Header Name.
          * `value` - The HTTP Header value.
        * `host` - The value for the host header which should be sent with this probe. If unspecified, the IP Address of the Pod is used as the host header. Setting a value for `Host` in `headers` can be used to override this for `HTTP` and `HTTPS` type probes.
        * `initial_delay` - The number of seconds elapsed after the container has started before the probe is initiated. Possible values are between `0` and `60`. Defaults to `0` seconds.
        * `interval_seconds` - How often, in seconds, the probe should run. Possible values are between `1` and `240`. Defaults to `10`
        * `path` - The URI to use with the `host` for http type probes. Not valid for `TCP` type probes. Defaults to `/`.
        * `port` - The port number on which to connect. Possible values are between `1` and `65535`.
        * `timeout` - Time in seconds after which the probe times out. Possible values are in the range `1` - `240`. Defaults to `1`.
        * `transport` - Type of probe. Possible values are `TCP`, `HTTP`, and `HTTPS`.
        * `volume_mounts` - A `volume_mounts` block as detailed below.
          * `name` - The name of the Volume to be mounted in the container.
          * `path` - The path in the container at which to mount this volume.
          * `sub_path` - The sub path of the volume to be mounted in the container.
      * `max_replicas` - The maximum number of replicas for this container.
      * `min_replicas` - The minimum number of replicas for this container.
      * `azure_queue_scale_rule` - One or more `azure_queue_scale_rule` blocks as defined below.
      * `name` - The name of the Scaling Rule
      * `queue_name` - The name of the Azure Queue
      * `queue_length` - The value of the length of the queue to trigger scaling actions.
      * `authentication` - One or more `authentication` blocks as defined below.
        * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
        * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `custom_scale_rule` - One or more `custom_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `custom_rule_type` - The Custom rule type. Possible values include: `activemq`, `artemis-queue`, `kafka`, `pulsar`, `aws-cloudwatch`, `aws-dynamodb`, `aws-dynamodb-streams`, `aws-kinesis-stream`, `aws-sqs-queue`, `azure-app-insights`, `azure-blob`, `azure-data-explorer`, `azure-eventhub`, `azure-log-analytics`, `azure-monitor`, `azure-pipelines`, `azure-servicebus`, `azure-queue`, `cassandra`, `cpu`, `cron`, `datadog`, `elasticsearch`, `external`, `external-push`, `gcp-stackdriver`, `gcp-storage`, `gcp-pubsub`, `graphite`, `http`, `huawei-cloudeye`, `ibmmq`, `influxdb`, `kubernetes-workload`, `liiklus`, `memory`, `metrics-api`, `mongodb`, `mssql`, `mysql`, `nats-jetstream`, `stan`, `tcp`, `new-relic`, `openstack-metric`, `openstack-swift`, `postgresql`, `predictkube`, `prometheus`, `rabbitmq`, `redis`, `redis-cluster`, `redis-sentinel`, `redis-streams`, `redis-cluster-streams`, `redis-sentinel-streams`, `selenium-grid`,`solace-event-queue`, and `github-runner`.
        * `metadata` -  A map of string key-value pairs to configure the Custom Scale Rule.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `http_scale_rule` - One or more `http_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `concurrent_requests` - The number of concurrent requests to trigger scaling.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `tcp_scale_rule` - One or more `tcp_scale_rule` blocks as defined below.
        * `name` - The name of the Scaling Rule
        * `concurrent_requests` - The number of concurrent requests to trigger scaling.
        * `authentication` - Zero or more `authentication` blocks as defined below.
            * `secret_name` - The name of the Container App Secret to use for this Scale Rule Authentication.
            * `trigger_parameter` - The Trigger Parameter name to use the supply the value retrieved from the `secret_name`.
      * `revision_suffix` - The suffix for the revision. This value must be unique for the lifetime of the Resource. If omitted the service will use a hash function to create one.
      * `termination_grace_period_seconds` - The time in seconds after the container is sent the termination signal before the process if forcibly killed.
      * `volume` - A `volume` block as detailed below.
        * `name` - The name of the volume.
        * `storage_name` - The name of the `AzureFile` storage.
        * `storage_type` - The type of storage volume. Possible values are `AzureFile`, `EmptyDir` and `Secret`. Defaults to `EmptyDir`.

    An `identity` block supports the following:
        * `type` - The type of managed identity to assign. Possible values are `SystemAssigned`, `UserAssigned`, and `SystemAssigned, UserAssigned` (to enable both).
        * `identity_ids` - - A list of one or more Resource IDs for User Assigned Managed identities to assign. Required when `type` is set to `UserAssigned` or `SystemAssigned, UserAssigned`.

    A `secrets` block supports the following:
        * `name` - The secret name.
        * `identity` - The identity to use for accessing the Key Vault secret reference. This can either be the Resource ID of a User Assigned Identity, or `System` for the System Assigned Identity.
        * `key_vault_secret_id` - The ID of a Key Vault secret. This can be a versioned or version-less ID.
        * `value` - The value for this secret.

    A `manual_trigger_config` block supports the following:
        * `parallelism` - Number of parallel replicas of a job that can run at a given time.
        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.

    A `event_trigger_config` block supports the following:
        * `parallelism` - Number of parallel replicas of a job that can run at a given time.
        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.
        * `scale` - A `scale` block as defined below.
            * `max_executions` - Maximum number of job executions that are created for a trigger.
            * `min_executions` - Minimum number of job executions that are created for a trigger.
            * `polling_interval_in_seconds` - Interval to check each event source in seconds.
            * `rules` - A `rules` block as defined below.
                * `name` - Name of the scale rule.
                * `custom_rule_type` - Type of the scale rule.
                * `metadata` - Metadata properties to describe the scale rule.
                * `authentication` - A `authentication` block as defined below.
                    * `secret_name` - Name of the secret from which to pull the auth params.
                    * `trigger_parameter` - Trigger Parameter that uses the secret.

    A `schedule_trigger_config` block supports the following:
        * `cron_expression` - Cron formatted repeating schedule of a Cron Job.
        * `parallelism` - Number of parallel replicas of a job that can run at a given time.
        * `replica_completion_count` - Minimum number of successful replica completions before overall job completion.

  Example output:
  ```
  output "name" {
    value = module.module_name.azurerm_container_app_job.name
   }
  ```
  DESCRIPTION

}
