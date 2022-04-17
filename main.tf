terraform {
    required_providers {  
        azurerm = {  
            source = "hashicorp/azurerm"
            version = "~> 3.0.2"  
        }  
  }
  
}


provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = "North Europe"
} 

resource "azurerm_virtual_network" "vnet" {
  name                = "AzureVirtualNetwork" 
  address_space       = ["10.0.0.0/16"]  
  location            = azurerm_resource_group.rg.location 
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "pubip" {
  name                = "AzurePublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "frwall" {
  name                = "AzureFirewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Standard"
  sku_name            = "AZFW_VNet"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.snet.id
    public_ip_address_id = azurerm_public_ip.pubip.id
  }
}

resource "azurerm_firewall_network_rule_collection" "firnetrule" {
  name                = "FirewallNetworkRuleCollection"
  azure_firewall_name = azurerm_firewall.frwall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "testrule"

    source_addresses = [
      "10.0.0.0/16",
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "8.8.8.8",
      "8.8.4.4",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}