# Deploy our VM that will be used as a bastion host
resource "azurerm_virtual_machine" "bastion_host" {
    name                  = "bastion-host"
    location              = "eastus"
    resource_group_name   = "aks-platform-private-rg"
    vm_size               = "Standard_B1s"
    network_interface_ids = [azurerm_network_interface.bastion_host_nic.id]
    delete_os_disk_on_termination = true
    delete_data_disks_on_termination = true

    storage_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }

    storage_os_disk {
        name              = "bastion-host-osdisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
        disk_size_gb      = 30
    }

    os_profile {
        computer_name  = "bastion-host"
        admin_username = "rodrigtech"
    }

    os_profile_linux_config {
        disable_password_authentication = true

        ssh_keys {
            path     = "/home/rodrigtech/.ssh/authorized_keys"
            key_data = file("~/.ssh/id_rsa.pub") # replace with the path to your public key
        }
    }

    custom_data = base64encode(<<-EOF
        #!/bin/bash
        sudo apt-get update
        sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
        curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
        AZ_REPO=$(lsb_release -cs)
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
        sudo apt-get update
        sudo apt-get install azure-cli
        sudo snap install kubectl --classic
    EOF
    )
}
resource "azurerm_network_interface" "bastion_host_nic" {
    name                = "bastion-host-nic"
    location            = "eastus"
    resource_group_name = "aks-platform-private-rg"

    ip_configuration {
        name                          = "bastion-host-ipconfig"
        subnet_id                     = azurerm_subnet.bastion_host_subnet.id
        private_ip_address_allocation = "Dynamic"
    }
}

resource "azurerm_subnet" "bastion_host_subnet" {
    name                 = "bastion-host-subnet"
    resource_group_name  = "aks-platform-private-rg"
    virtual_network_name = azurerm_virtual_network.bastion_vnet.name
    address_prefixes      = ["10.1.1.0/24"]
}