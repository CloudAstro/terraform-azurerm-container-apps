resource "azurerm_container_app_job" "this" {
  count = (lower(var.container_type) == "job") ? 1 : 0

  name                         = var.name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  replica_timeout_in_seconds   = var.replica_timeout_in_seconds
  workload_profile_name        = var.workload_profile_name
  replica_retry_limit          = var.replica_retry_limit
  tags                         = var.tags

  dynamic "template" {
    for_each = var.template != null ? [var.template] : null

    content {
      dynamic "container" {
        for_each = template.value.container == null ? {} : template.value.container

        content {
          name              = container.value.name
          cpu               = container.value.cpu
          memory            = container.value.memory
          image             = container.value.image
          args              = container.value.args
          command           = container.value.command
          ephemeral_storage = container.value.ephemeral_storage

          dynamic "env" {
            for_each = container.value.env == null ? [] : container.value.env

            content {
              name        = env.value.name
              value       = env.value.value
              secret_name = env.value.secret_name
            }
          }

          dynamic "liveness_probe" {
            for_each = container.value.liveness_probe == null ? [] : container.value.liveness_probe

            content {
              port                    = liveness_probe.value.port
              transport               = liveness_probe.value.transport
              failure_count_threshold = liveness_probe.value.failure_count_threshold
              host                    = liveness_probe.value.host
              initial_delay           = liveness_probe.value.initial_delay
              interval_seconds        = liveness_probe.value.interval_seconds
              path                    = liveness_probe.value.path
              timeout                 = liveness_probe.value.timeout

              dynamic "header" {
                for_each = liveness_probe.value.header == null ? [] : liveness_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "readiness_probe" {
            for_each = container.value.readiness_probe == null ? [] : container.value.readiness_probe

            content {
              port                    = readiness_probe.value.port
              transport               = readiness_probe.value.transport
              failure_count_threshold = readiness_probe.value.failure_count_threshold
              host                    = readiness_probe.value.host
              interval_seconds        = readiness_probe.value.interval_seconds
              path                    = readiness_probe.value.path
              success_count_threshold = readiness_probe.value.success_count_threshold
              timeout                 = readiness_probe.value.timeout

              dynamic "header" {
                for_each = readiness_probe.value.header == null ? [] : readiness_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "startup_probe" {
            for_each = container.value.startup_probe == null ? [] : container.value.startup_probe

            content {
              port                    = startup_probe.value.port
              transport               = startup_probe.value.transport
              failure_count_threshold = startup_probe.value.failure_count_threshold
              host                    = startup_probe.value.host
              interval_seconds        = startup_probe.value.interval_seconds
              path                    = startup_probe.value.path
              timeout                 = startup_probe.value.timeout
              initial_delay           = startup_probe.value.initial_delay
              dynamic "header" {
                for_each = startup_probe.value.header == null ? [] : startup_probe.value.header

                content {
                  name  = header.value.name
                  value = header.value.value
                }
              }
            }
          }

          dynamic "volume_mounts" {
            for_each = container.value.volume_mounts == null ? [] : container.value.volume_mounts

            content {
              name     = volume_mounts.value.name
              path     = volume_mounts.value.path
              sub_path = volume_mounts.value.sub_path
            }
          }
        }
      }

      dynamic "init_container" {
        for_each = template.value.init_container == null ? {} : template.value.init_container

        content {
          name              = init_container.value.name
          cpu               = init_container.value.cpu
          memory            = init_container.value.memory
          image             = init_container.value.image
          args              = init_container.value.args
          command           = init_container.value.command
          ephemeral_storage = init_container.value.ephemeral_storage

          dynamic "env" {
            for_each = init_container.value.env == null ? [] : init_container.value.env

            content {
              name        = env.value.name
              value       = env.value.value
              secret_name = env.value.secret_name
            }
          }

          dynamic "volume_mounts" {
            for_each = init_container.value.volume_mounts == null ? [] : init_container.value.volume_mounts

            content {
              name = volume_mounts.value.name
              path = volume_mounts.value.path
            }
          }
        }
      }

      dynamic "volume" {
        for_each = template.value.volume == null ? [] : template.value.volume

        content {
          name         = volume.value.name
          storage_name = volume.value.storage_name
          storage_type = volume.value.storage_type
        }
      }
    }
  }

  ## Resources supporting both SystemAssigned and UserAssigned
  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  dynamic "secret" {
    for_each = var.secret != null ? var.secret : {}

    content {
      name                = secret.value.name
      identity            = secret.value.identity
      key_vault_secret_id = secret.value.key_vault_secret_id
      value               = secret.value.value == null ? null : sensitive(secret.value.value)
    }
  }

  dynamic "registry" {
    for_each = var.registry == null ? {} : var.registry

    content {
      identity             = registry.value.identity
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
      server               = registry.value.server
    }
  }

  dynamic "manual_trigger_config" {
    for_each = var.manual_trigger_config == null ? [] : [var.manual_trigger_config]

    content {
      parallelism              = manual_trigger_config.value.parallelism
      replica_completion_count = manual_trigger_config.value.replica_completion_count
    }
  }

  dynamic "event_trigger_config" {
    for_each = var.event_trigger_config == null ? [] : var.event_trigger_config

    content {
      parallelism              = event_trigger_config.value.parallelism
      replica_completion_count = event_trigger_config.value.replica_completion_count

      dynamic "scale" {
        for_each = event_trigger_config.value.scale == null ? {} : event_trigger_config.value.scale

        content {
          max_executions              = scale.value.max_executions
          min_executions              = scale.value.min_executions
          polling_interval_in_seconds = scale.value.polling_interval_in_seconds

          dynamic "rules" {
            for_each = scale.value.rules == null ? {} : scale.value.rules

            content {
              name             = rules.value.name
              custom_rule_type = rules.value.custom_rule_type
              metadata         = rules.value.metadata

              dynamic "authentication" {
                for_each = rules.value.authentication == null ? {} : rules.value.authentication

                content {
                  secret_name       = authentication.value.secret_name
                  trigger_parameter = authentication.value.trigger_parameter
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "schedule_trigger_config" {
    for_each = var.schedule_trigger_config == null ? [] : var.schedule_trigger_config

    content {
      cron_expression          = schedule_trigger_config.value.cron_expression
      parallelism              = schedule_trigger_config.value.parallelism
      replica_completion_count = schedule_trigger_config.value.replica_completion_count
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

resource "azurerm_management_lock" "lock_job" {
  count = var.lock != null && var.container_type == "job" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_container_app_job.this[0].id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
