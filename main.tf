
provider "azurerm"{
    features {
    }
}
terraform {
  required_providers {
    azurerm={
        source = "hashicorp/azurerm"
        version= "3.52.0"
    }
  }
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "Vnet" {
  name = "vnet-test-eastus"
  address_space = ["10.1.0.0/16"]
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet" {
  name = "snet-test-eastus"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes = ["10.1.0.0/24"]
}
resource "azurerm_subnet" "bastion" {
  name = "AzureBastionSubnet"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.Vnet.name
  address_prefixes = ["10.1.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name = "nic-test"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name = "nic-config"
    subnet_id = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  
  name                = "vm-test-eastus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  
  admin_username      = "SanketVM1"
  admin_password      = "Sanket@VM1"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  for_each = local.zones
  
  zone = each.value
}
locals {
  zones = toset(["1"])
}


resource "azurerm_public_ip" "ip" {
  name                = "bastionip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name = "vnet-test-eastus-bastion"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "ip-config"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.ip.id
  }
}