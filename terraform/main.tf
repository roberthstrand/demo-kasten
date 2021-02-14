module "kubernetes" {
  source  = "roberthstrand/kubernetes/azurerm"
  version = "1.2.1"

  name           = "k10-demo"
  resource_group = azurerm_resource_group.cluster.name
  subnet_id      = azurerm_subnet.aks.id
  # The default deployment is managed, with RBAC. This means that you have to define a group or groups
  # that will have admin rights to the cluster. Check settings.tf to see how we can more easily refer to
  # group names, rather than object IDs. To refer to more than one group at the time, you can use the
  # azuread_groups data source like we do here.
  admin_groups = data.azuread_groups.admins.object_ids

  default_node_pool = [{
    name                = "default"
    vm_size             = "Standard_D2s_v3"
    node_count          = 1
    enable_auto_scaling = false
    min_count           = null
    max_count           = null
    additional_settings = {
      max_pods        = 100
      os_disk_size_gb = 60
    }
  }]

  namespaces = [
    {
      name = "kasten-io"
      annotations = {
        source = "terraform"
      }
      labels = {
        environment = "production"
        type        = "backup"
      }
    },
    {
      name = "nginx-test"
      annotations = {
        source = "terraform"
      }
      labels = {
        environment = "production"
      }
    }
  ]

  depends_on = [azurerm_resource_group.cluster]
}

resource "azurerm_resource_group" "cluster" {
  name     = "k10-demo-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "cluster" {
  name                = "k10-demo-vnet"
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name
  address_space       = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.cluster.name
  virtual_network_name = azurerm_virtual_network.cluster.name
  address_prefixes     = ["10.0.0.0/22"]
}
resource "azurerm_storage_account" "kasten" {
  name                     = "rsk10storagedemo"
  location                 = azurerm_resource_group.cluster.location
  resource_group_name      = azurerm_resource_group.cluster.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
resource "azurerm_storage_container" "kasten" {
  name                  = "backup"
  storage_account_name  = azurerm_storage_account.kasten.name
  container_access_type = "private"
}
output "storage" {
  value = azurerm_storage_account.kasten.primary_access_key
}
