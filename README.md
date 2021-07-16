tcb-azure-m5

BootCamp Azure – Module 5

Azure File Share + Azure Backup + Azure Bastion

Requeriments and Instructions:

- Run commands in a linux host (needs terraform);
- Create azure user principal: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret
- Set Azure parameters.tf and tfvar.tf
- Generate your ssh key pair (use key.pem and key.pub names for script compatibility);
- terraform init -> terraform validate -> terraform plan -out plan -> terraform apply plan;
- Deployment takes more than 15 minutes. Let´s take coffee
- If you want to deploy client machines with custon data for automatic mount share:
 - Comment client 1 and 2 blocks in main.tf and runs terraform normaly;
 - Copy mount script for linux in Azure Console of created share;
 - Paste script in client.sh;
 - Uncomment client 1 and 2 blocks in main.tf and uncomment this line in both: #custom_data     = filebase64("client.sh")
 - Run terraform again.