resource "azurerm_resource_group" "ca-rg" {
  name     = "rg-container-app-example"
  location = "germanywestcentral"
}

module "ca-environment" {
  source = "git@ssh.dev.azure.com:v3/DevOpsCloudAstro/ca-terraform-modules/azure//tf-azurerm-container-app-environment"

  name                = "ca-env-dev"
  location            = azurerm_resource_group.ca-rg.location
  resource_group_name = azurerm_resource_group.ca-rg.name
}

# If containter_type is "app", it will create a Container App.
module "container_app" {
  source = "../../"

  container_type               = "app"
  name                         = "example-container-app"
  resource_group_name          = azurerm_resource_group.ca-rg.name
  location                     = module.ca-environment.resource.location
  container_app_environment_id = module.ca-environment.resource.id
  revision_mode                = "Single"

  template = {
    container = {
      app = {
        name   = "app"
        image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        cpu    = 0.5
        memory = "1.0Gi"
      }
    }
  }
}

# If container_type is "job", it will create a Container Job.
module "container_job" {
  source = "../../"

  container_type               = "job"
  name                         = "example-container-job"
  resource_group_name          = azurerm_resource_group.ca-rg.name
  location                     = azurerm_resource_group.ca-rg.location
  container_app_environment_id = module.ca-environment.resource.id
  revision_mode                = "Single"
  replica_timeout_in_seconds   = 300

  template = {
    container = {
      job = {
        name   = "job"
        image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
        cpu    = 0.5
        memory = "1.0Gi"
      }
    }
  }

  schedule_trigger_config = [
    {
      cron_expression = "0 2 * * *" # Every day at 2 AM
    }
  ]
}
