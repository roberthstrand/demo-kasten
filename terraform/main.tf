module "kubernetes" {
  source  = "roberthstrand/kubernetes/azurerm"
  version = "1.1.0"

  name           = "kastendemo"
  resource_group = azurerm_resource_group.cluster.name
  subnet_id      = azurerm_subnet.aks.id
  # The default deployment is managed, with RBAC. This means that you have to define a group or groups
  # that will have admin rights to the cluster. Check settings.tf to see how we can more easily refer to
  # group names, rather than object IDs. To refer to more than one group at the time, you can use the
  # azuread_groups data source like we do here.
  admin_groups = data.azuread_groups.admins.object_ids

  additional_node_pools = [{
    name                = "pool01"
    vm_size             = "Standard_D2s_v3"
    node_count          = 2
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 3
    node_labels = {
      "type" = "karsten"
    }
    tags = null
    additional_settings = {
      max_pods = 30
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
    }
  ]

  depends_on = [azurerm_resource_group.cluster]
}

resource "azurerm_resource_group" "cluster" {
  name     = "kastendemo-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "cluster" {
  name                = "kastendemo-vnet"
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "aks"
  resource_group_name  = azurerm_resource_group.cluster.name
  virtual_network_name = azurerm_virtual_network.cluster.name
  address_prefixes     = ["10.0.0.0/24"]
}
