resource "azurerm_container_app" "this" {
  count = (lower(var.container_type) == "app") ? 1 : 0

  container_app_environment_id = var.container_app_environment_id
  name                         = var.name
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode
  tags                         = var.tags
  workload_profile_name        = var.workload_profile_name

  dynamic "template" {
    for_each = var.template != null ? [var.template] : null

    content {
      max_replicas                     = template.value.max_replicas
      min_replicas                     = template.value.min_replicas
      revision_suffix                  = template.value.revision_suffix
      termination_grace_period_seconds = template.value.termination_grace_period_seconds

      dynamic "init_container" {
        for_each = template.value.init_container == null ? {} : template.value.init_container

        content {
          args              = init_container.value.args
          command           = init_container.value.command
          cpu               = init_container.value.cpu
          ephemeral_storage = init_container.value.ephemeral_storage
          image             = init_container.value.image
          memory            = init_container.value.memory
          name              = init_container.value.name
          dynamic "env" {
            for_each = init_container.value.env == null ? [] : init_container.value.env

            content {
              name        = env.value.name
              secret_name = env.value.secret_name
              value       = env.value.value
            }
          }
          dynamic "volume_mounts" {
            for_each = init_container.value.volume_mounts == null ? [] : init_container.value.volume_mounts

            content {
              name     = volume_mounts.value.name
              path     = volume_mounts.value.path
              sub_path = volume_mounts.value.sub_path
            }
          }
        }
      }

      dynamic "container" {
        for_each = template.value.container == null ? {} : template.value.container

        content {
          args              = container.value.args
          command           = container.value.command
          cpu               = container.value.cpu
          ephemeral_storage = container.value.ephemeral_storage
          image             = container.value.image
          memory            = container.value.memory
          name              = container.value.name
          dynamic "env" {
            for_each = container.value.env == null ? [] : container.value.env

            content {
              name        = env.value.name
              secret_name = env.value.secret_name
              value       = env.value.value
            }
          }

          dynamic "liveness_probe" {
            for_each = container.value.liveness_probe == null ? [] : container.value.liveness_probe

            content {
              failure_count_threshold = liveness_probe.value.failure_count_threshold
              host                    = liveness_probe.value.host
              initial_delay           = liveness_probe.value.initial_delay
              interval_seconds        = liveness_probe.value.interval_seconds
              path                    = liveness_probe.value.path
              port                    = liveness_probe.value.port
              timeout                 = liveness_probe.value.timeout
              transport               = liveness_probe.value.transport

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
              failure_count_threshold = readiness_probe.value.failure_count_threshold
              host                    = readiness_probe.value.host
              initial_delay           = readiness_probe.value.initial_delay
              interval_seconds        = readiness_probe.value.interval_seconds
              path                    = readiness_probe.value.path
              port                    = readiness_probe.value.port
              success_count_threshold = readiness_probe.value.success_count_threshold
              timeout                 = readiness_probe.value.timeout
              transport               = readiness_probe.value.transport

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
              failure_count_threshold = startup_probe.value.failure_count_threshold
              host                    = startup_probe.value.host
              initial_delay           = startup_probe.value.initial_delay
              interval_seconds        = startup_probe.value.interval_seconds
              path                    = startup_probe.value.path
              port                    = startup_probe.value.port
              timeout                 = startup_probe.value.timeout
              transport               = startup_probe.value.transport
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

      dynamic "azure_queue_scale_rule" {
        for_each = template.value.azure_queue_scale_rules == null ? [] : template.value.azure_queue_scale_rules

        content {
          name         = azure_queue_scale_rule.value.name
          queue_length = azure_queue_scale_rule.value.queue_length
          queue_name   = azure_queue_scale_rule.value.queue_name

          dynamic "authentication" {
            for_each = azure_queue_scale_rule.value.authentication == null ? [] : azure_queue_scale_rule.value.authentication

            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "custom_scale_rule" {
        for_each = template.value.custom_scale_rules == null ? [] : template.value.custom_scale_rules

        content {
          name             = custom_scale_rule.value.name
          custom_rule_type = custom_scale_rule.value.custom_rule_type
          metadata         = custom_scale_rule.value.metadata

          dynamic "authentication" {
            for_each = custom_scale_rule.value.authentication == null ? [] : custom_scale_rule.value.authentication

            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "http_scale_rule" {
        for_each = template.value.http_scale_rules == null ? [] : template.value.http_scale_rules

        content {
          name                = http_scale_rule.value.name
          concurrent_requests = http_scale_rule.value.concurrent_requests

          dynamic "authentication" {
            for_each = http_scale_rule.value.authentication == null ? [] : http_scale_rule.value.authentication

            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "tcp_scale_rule" {
        for_each = template.value.tcp_scale_rules == null ? [] : template.value.tcp_scale_rules

        content {
          name                = tcp_scale_rule.value.name
          concurrent_requests = tcp_scale_rule.value.concurrent_requests

          dynamic "authentication" {
            for_each = tcp_scale_rule.value.authentication == null ? [] : tcp_scale_rule.value.authentication

            content {
              secret_name       = authentication.value.secret_name
              trigger_parameter = authentication.value.trigger_parameter
            }
          }
        }
      }

      dynamic "volume" {
        for_each = template.value.volume == null ? [] : template.value.volume

        content {
          name          = volume.value.name
          storage_name  = volume.value.storage_name
          storage_type  = volume.value.storage_type
          mount_options = volume.value.mount_options
        }
      }
    }
  }

  dynamic "dapr" {
    for_each = var.dapr == null ? [] : [var.dapr]

    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
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

  dynamic "ingress" {
    for_each = var.ingress != null ? [var.ingress] : null

    content {
      allow_insecure_connections = ingress.value.allow_insecure_connections
      external_enabled           = ingress.value.external_enabled
      fqdn                       = ingress.value.fqdn
      target_port                = ingress.value.target_port
      exposed_port               = ingress.value.exposed_port
      transport                  = ingress.value.transport
      client_certificate_mode    = ingress.value.client_certificate_mode

      dynamic "cors" {
        for_each = ingress.value.cors == null ? [] : [ingress.value.cors]

        content {
          allowed_origins           = ingress.value.cors.allowed_origins
          allow_credentials_enabled = ingress.value.cors.allow_credentials_enabled
          allowed_headers           = ingress.value.cors.allowed_headers
          allowed_methods           = ingress.value.cors.allowed_methods
          exposed_headers           = ingress.value.cors.exposed_headers
        }
      }

      dynamic "ip_security_restriction" {
        for_each = ingress.value.ip_security_restriction == null ? [] : ingress.value.ip_security_restriction

        content {
          action           = ip_security_restriction.value.action
          description      = ip_security_restriction.value.description
          ip_address_range = ip_security_restriction.value.ip_address_range
          name             = ip_security_restriction.value.name
        }
      }

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weight == null ? [] : ingress.value.traffic_weight

        content {
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
          percentage      = traffic_weight.value.percentage
        }
      }

      dynamic "custom_domain" {
        for_each = ingress.value.custom_domain == null ? [] : [ingress.value.custom_domain]

        content {
          certificate_binding_type = custom_domain.value.certificate_binding_type
          certificate_id           = custom_domain.value.certificate_id
          name                     = custom_domain.value.name
        }
      }
    }
  }

  dynamic "registry" {
    for_each = var.registry == null ? {} : var.registry

    content {
      server               = registry.value.server
      identity             = registry.value.identity
      password_secret_name = registry.value.password_secret_name
      username             = registry.value.username
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

resource "azurerm_management_lock" "lock_app" {
  count = var.lock != null && var.container_type == "app" ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_container_app.this[0].id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}
