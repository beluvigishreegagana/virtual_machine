resource "azurerm_public_ip" "public_ip" {
  name                = "${var.name}_public_ip"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name}_nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}



resource "azurerm_network_security_group" "nsg" {
  name                = "${var.name}_nsg"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-http"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp" # Should be "Tcp" instead of "http"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine" "vm" {
  name                  = var.name
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = var.vm_size
  availability_set_id   = var.availability_set_id

  storage_os_disk {
    name              = "${var.name}_os_disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  dynamic "storage_image_reference" {
    for_each = var.os_type == "windows" ? [1] : []
    content {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
    }
  }

  dynamic "storage_image_reference" {
    for_each = var.os_type == "linux" ? [1] : []
    content {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }
  }

  os_profile {
    computer_name  = var.name
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  dynamic "os_profile_linux_config" {
    for_each = var.os_type == "linux" ? [1] : []
    content {
      disable_password_authentication = false
    }
  }

  dynamic "os_profile_windows_config" {
    for_each = var.os_type == "windows" ? [1] : []
    content {}
  }
}
