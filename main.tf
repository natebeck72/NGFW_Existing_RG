# Bring in resources to Terraform for use in deployment of new NGFW

# Existing Resource Group

data "azurerm_resource_group" "ResourceGroup" {
    name = var.rg_name
}

# Existing Network Security Group

data "azurerm_network_security_group" "NSG" {
    name = var.nsg_name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}

# Existing Route Tables

data "azurerm_route_table" "RouteTableInternal" {
    name = var.introutetable_name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}

data "azurerm_route_table" "RouteTableExternal" {
    name = var.extroutetable_name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}

# Existing Virtual Networks

data "azurerm_virtual_network" "vnet-name" {
    name = var.virtual_network_name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name 
}


# Existing Subnets

data "azurerm_subnet" "Mgmt" {
    name = var.mgmt_subnet
    virtual_network_name = data.azurerm_virtual_network.vnet-name.name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}

data "azurerm_subnet" "Trust" {
    name = var.trust_subnet
    virtual_network_name = data.azurerm_virtual_network.vnet-name.name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}

data "azurerm_subnet" "Untrust" {
    name = var.untrust_subnet
    virtual_network_name = data.azurerm_virtual_network.vnet-name.name
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
}






# Create new External IP's

resource "azurerm_public_ip" "firewall-mgmtip" {
    name = "ngfw_mgmt_ip"
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
    location = data.azurerm_resource_group.ResourceGroup.location
    allocation_method = "static"
}

resource "azurerm_public_ip" "FW_eth1_extip" {
    name = "ngfw_eth1_extip"
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
    location = data.azurerm_resource_group.ResourceGroup.location
    allocation_method = "static"
}

# Create new storage account for the new NGFW

resource "azurerm_storage_account" "ngfw_storage" {
    name = "ngfwstordiag"
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
    location = data.azurerm_resource_group.ResourceGroup.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    public_network_access_enabled = "false"
    blob_properties {
      delete_retention_policy {
        days = 7
      }
    }
    queue_properties {
      logging {
        delete = true
        read = true
        write = true
        version = "1.0"
        retention_policy_days = 10
      }
    }
    network_rules {
      default_action = "Deny"
    }
}

resource "azurerm_storage_account" "blob" {
    name = "ngfwstorblob"
    resource_group_name = data.azurerm_resource_group.ResourceGroup.name
    location = data.azurerm_resource_group.ResourceGroup.location
    account_tier = "Standard"
    account_replication_type = "LRS"
    public_network_access_enabled = "false"
    account_kind = "BlobStorage"
    blob_properties {
      delete_retention_policy {
        days = 7
      }
    }
    network_rules {
      default_action = "Deny"
    }
}

# Create new Network Interfaces for NGFW

resource "azurerm_network_interface" "fw-eth0" {
  name = "ngfw-eth0"
  resource_group_name = data.azurerm_resource_group.ResourceGroup.name
  location = data.azurerm_resource_group.ResourceGroup.location

  ip_configuration {
    name = "ipconfig_mgmt"
    subnet_id = data.azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.mgmtip
    primary = true
    public_ip_address_id = azurerm_public_ip.firewall-mgmtip.id
  }
  depends_on = [ azurerm_public_ip.firewall-mgmtip ]
}

resource "azurerm_network_interface" "fw-eth1" {
  name = ngfw-eth1
  resource_group_name = data.azurerm_resource_group.ResourceGroup.name
  location = data.azurerm_resource_group.ResourceGroup.location
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name = "ifconfig_untrust"
    subnet_id = data.azurerm_subnet.Untrust.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.untrustip
    public_ip_address_id = azurerm_public_ip.FW_eth1_extip
  }
  depends_on = [ azurerm_public_ip.FW_eth1_extip ]
}

resource "azurerm_network_interface" "fw-eth2" {
  name = "ngfw-eth2"
  resource_group_name = data.azurerm_resource_group.ResourceGroup.name
  location = data.azurerm_resource_group.ResourceGroup.location
  enable_ip_forwarding = true
  enable_accelerated_networking = true

  ip_configuration {
    name = "ifconfig_trust"
    subnet_id = data.azurerm_subnet.Trust.id
    private_ip_address_allocation = "Static"
    private_ip_address = var.trustip
  }
}

resource "azurerm_network_interface_security_group_association" "fw-eth0" {
  network_interface_id = azurerm_network_interface.fw-eth0.id
  network_security_group_id = data.azurerm_network_security_group.NSG.id
  depends_on = [ azurerm_network_interface.fw-eth0 ]
}

resource "azurerm_network_interface_security_group_association" "fw-eth1" {
  network_interface_id = azurerm_network_interface.fw-eth1.id
  network_security_group_id = data.azurerm_network_security_group.NSG.id
  depends_on = [ azurerm_network_interface.fw-eth1 ]
}

resource "azurerm_network_interface_security_group_association" "fw-eth2" {
  network_interface_id = azurerm_network_interface.fw-eth2.id
  network_security_group_id = data.azurerm_network_security_group.NSG.id
  depends_on = [ azurerm_network_interface.fw-eth2 ]
}

resource "azurerm_virtual_machine" "NGFW" {
  name = "var.ngfwname"
  resource_group_name = data.azurerm_resource_group.ResourceGroup.name
  location = data.azurerm_resource_group.ResourceGroup.location
  vm_size = "Standard_DS3_v2"
  plan {
    name = "byol"
    publisher = "paloaltonetworks"
    product = "vmseries-flex"
  }
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer = "vmseries-flex"
    sku = "byol"
    version = "${var.firewall_version}"
  }
  storage_os_disk {
    name = lower("${var.ngfwname}-osdisk")
    vhd_uri = "${azurerm_storage_account.ngfw_storage.primary_blob_endpoint}vhds/${var.ngfwname}-osdisk1.vhd"
    caching = "Readonly"
    create_option = "FromImage"
  }
  os_profile {
    computer_name = "${var.ngfwname}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }
  primary_network_interface_id = azurerm_network_interface.fw-eth0.id
  network_interface_ids = [
    azurerm_network_interface.fw-eth0.id,
    azurerm_network_interface.fw-eth1.id,
    azurerm_network_interface.fw-eth2.id
  ]
  os_profile_linux_config {
    disable_password_authentication = false
  }
  depends_on = [ 
    azurerm_network_interface_security_group_association.fw-eth0,
    azurerm_network_interface_security_group_association.fw-eth1,
    azurerm_network_interface_security_group_association.fw-eth2
   ]
}
