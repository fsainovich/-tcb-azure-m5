#Create Resource Group
resource "azurerm_resource_group" "TCB-AZURE-M5" {
  name     = var.RG_NAME
  location = var.AZURE_LOCATION
}

#Create VNET
resource "azurerm_virtual_network" "MAIN" {
  depends_on = [
    azurerm_resource_group.TCB-AZURE-M5
  ]
  name                = "VNET-MAIN"
  address_space       = [var.VNET_CIDR]
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
}

#Create Internal Subnet
resource "azurerm_subnet" "SUBNET-INTERNAL" {
  name                  = "SUBNET-INTERNAL"
  resource_group_name   = var.RG_NAME
  virtual_network_name  = azurerm_virtual_network.MAIN.name
  address_prefixes      = [var.SUBNET_INTERNAL_CIDR]
}


#Create Storage Account
resource "azurerm_storage_account" "storage_acount" {
  depends_on = [
    azurerm_resource_group.TCB-AZURE-M5
  ]
  name                     = var.SA_NAME
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION  
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind  = "StorageV2"
  min_tls_version = "TLS1_2"
  
}

#Create Azure File Share
resource "azurerm_storage_share" "share" {
  name                 = "share"
  storage_account_name = azurerm_storage_account.storage_acount.name
  quota                = 1

  acl {
    id = "MTIzNDU2Nzg5MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTI"

    access_policy {
      permissions = "rwdl"
      start       = "2019-07-02T09:38:21.0000000Z"
      expiry      = "2019-07-02T10:38:21.0000000Z"
    }
  }
}

#Create VNIC for Client1
resource "azurerm_network_interface" "VNIC1" {
  name                = "VNIC1"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION

  ip_configuration {
    name                          = "ip_config"
    subnet_id                     = azurerm_subnet.SUBNET-INTERNAL.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create Client1
resource "azurerm_virtual_machine" "Client1" {
  name                  = "Client1"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  network_interface_ids = [azurerm_network_interface.VNIC1.id]
  vm_size               = "Standard_B1s"
  
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name   = "Client1"
    admin_username  = "azureuser"
    #custom_data     = filebase64("client.sh")
    admin_password  = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false        
    ssh_keys {       
        key_data  =  file("key.pub")    
        path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

#Create VNIC for Client2
resource "azurerm_network_interface" "VNIC2" {
  name                = "VNIC2"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.SUBNET-INTERNAL.id
    private_ip_address_allocation = "Dynamic"
  }
}

#Create Client2
resource "azurerm_virtual_machine" "Client2" {
  name                  = "Client2"
  resource_group_name   = var.RG_NAME
  location              = var.AZURE_LOCATION
  network_interface_ids = [azurerm_network_interface.VNIC2.id]
  vm_size               = "Standard_B1s"
  
  delete_os_disk_on_termination     = true
  delete_data_disks_on_termination  = true  

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "disk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name   = "Client2"
    admin_username  = "azureuser"
    #custom_data     = filebase64("client.sh")
    admin_password  = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false        
    ssh_keys {       
        key_data  =  file("key.pub")    
        path      = "/home/azureuser/.ssh/authorized_keys"
    }
  }
}

#Create Azure Vault
resource "azurerm_recovery_services_vault" "VAULT" {
  depends_on = [
    azurerm_resource_group.TCB-AZURE-M5
  ]
  name                = "VAULT"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
  sku                 = "Standard"
}

#Create Azure Backup policy
resource "azurerm_backup_policy_file_share" "policy" {
  name                = "share-vault-policy"
  resource_group_name = var.RG_NAME  
  recovery_vault_name = azurerm_recovery_services_vault.VAULT.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }  
}

#Create Azure Backup Protection Container
resource "azurerm_backup_container_storage_account" "protection-container" {
  resource_group_name = var.RG_NAME  
  recovery_vault_name = azurerm_recovery_services_vault.VAULT.name
  storage_account_id  = azurerm_storage_account.storage_acount.id
}

#Create Azure Backup routine for Azure Share
resource "azurerm_backup_protected_file_share" "share1" {
  resource_group_name       = var.RG_NAME  
  recovery_vault_name       = azurerm_recovery_services_vault.VAULT.name
  source_storage_account_id = azurerm_backup_container_storage_account.protection-container.storage_account_id
  source_file_share_name    = azurerm_storage_share.share.name
  backup_policy_id          = azurerm_backup_policy_file_share.policy.id
}

# Create Bastion Subnet
resource "azurerm_subnet" "SUBNET-BASTION" {
  name                  = "AzureBastionSubnet" # mandatory name -do not rename-
  address_prefixes      = [var.SUBNET_BASTION_CIDR]
  virtual_network_name  = azurerm_virtual_network.MAIN.name
  resource_group_name   = var.RG_NAME
}

#Create Public IP for BASTION
resource "azurerm_public_ip" "bastion-ip" {
  depends_on = [
    azurerm_resource_group.TCB-AZURE-M5
  ]
  name                = "bastion-ip"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION
  allocation_method   = "Static"
  sku = "Standard"
}

#Create Azure Bastion Access
resource "azurerm_bastion_host" "JumpServer" {
  name                = "JumpServer"
  resource_group_name = var.RG_NAME
  location            = var.AZURE_LOCATION

  ip_configuration {
    name                 = "Config"
    subnet_id            = azurerm_subnet.SUBNET-BASTION.id
    public_ip_address_id = azurerm_public_ip.bastion-ip.id
  }
}