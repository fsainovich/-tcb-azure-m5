#Azure Location
variable "AZURE_LOCATION" {
    type = string
    default = "eastus"
}

#RG NameAzure Location
variable "RG_NAME" {
    type = string
    default = "TCB-AZ-M5"
}

#Storage account namen
variable "SA_NAME" {
    type = string
    default = "fsainovich"
}

#VNET CIDR
variable "VNET_CIDR" {
    type = string
    default = "10.0.0.0/16"
}

#SUBNET_INTERNAL_CIDR
variable "SUBNET_INTERNAL_CIDR" {
    type = string
    default = "10.0.1.0/24"
}

#SUBNET_BASTION_CIDR
variable "SUBNET_BASTION_CIDR" {
    type = string
    default = "10.0.10.0/24"
}

#Subscription ID
variable "SUB_ID" {
    type = string
    default = ""
}

#Principal Client ID
variable "CLI_ID" {
    type = string
    default = ""
}

#Principal Client SECRET
variable "CLI_SECRET" {
    type = string
    default = ""
} 

#Tenant ID  
variable "TEN_ID" {
    type = string
    default = ""
} 