# Variables to bring in so that we know the current infrastructure

variable "rg_name" {
    type = string
    description = "name of existing Resource Group in Azure"
}

variable "nsg_name" {
    type = string
    description = "name of existing Network Security Group in Azure RG"
}

variable "introutetable_name" {
    type = string
    description = "name of existing internal Route Table in Azure RG"
}

variable "extroutetable_name" {
    type = string
    description = "name of existing external route table in azure RG"
}

variable "virtual_network_name" {
    type = string 
    description = "name of existing virtual network name in azure rg"
}

variable "mgmt_subnet" {
    type = string
    description = "name of existing mgmt subnet in azure rg"
}

variable "trust_subnet" {
    type = string
    description = "name of existing trust subnet in azure rg"
}

variable "untrust_subnet" {
    type = string
    description = "name of existing untrust subnet in azure rg"
}

# Variables used in the deployment of the new NGFW

variable "admin_username" {
    type = string
    description = "username pushed into the NGFW"
}

variable "admin_password" {
    type = string
    description = "password pushed into the NGFW for username provided"
}

variable "firewall_version" {
    type = string
    description = "Version of the NGFW to deploy"
    default = "latest"
}

variable "mgmtip" {
    type = string
    description = "internal mgmt ip of the firewall"
}

variable "trustip" {
    type = string
    description = "internal trust ip of the firewall"
}

variable "untrustip" {
    type = string
    description = "internal untrust ip of the firewall"
}

variable "ngfwname" {
    type = string
    description = "Name of the new firewall in Azure"
}