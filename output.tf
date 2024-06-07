
output "network_interface_id" {
  value = azurerm_network_interface.nic.id
}

output "network_interface_ids" {
  value = azurerm_network_interface.nic[*].id
}
