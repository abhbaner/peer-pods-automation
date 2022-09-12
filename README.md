# Peer pods automation

## Installing Terraform

For MacOS one can use brew to install terraform
```$ brew install terraform```

For other OS here is the link for the tutorial video by Terraform's team
https://learn.hashicorp.com/tutorials/terraform/install-cli#install-terraform

## Creating AWS access key and secret key
1. Log in to the AWS web management console 
2. Click on your username (top right) 
3. Click on security credentials 
4. Under AWS IAM Credentials tab in *'Access keys for CLI, SDK, & API access'* section click on *'create access key'* - copy and save the access key & secret key

## Creating ssh keypair for EC2 cli access
1. Log in to the AWS web management console
2. Make sure you are on Oregon region (US WEST) 
3. Go to EC2 Dashboard 
4. Under 'Network and Security' you will find the option 'Keypairs' - add a new one by clicking on 'Create Keypair' and save it to your local machine. 

## Execution of the script

1. Please create a ```terraform.tfvars``` file in the same directory as ```aws_env_setup.tf & variables.tf```. 
```terraform.tfvars``` would have the access key, secret key and sshkeypair name for your account. Below is an example of the contents of ```terrform.tfvars```, 
```console
aws_access_key_id = "ABCDEFGHIJKLM"  
aws_secret_key_id = "xxxxxxxxxxxxxxxxxx" 
ec2_ssh_key_name = "example-ssh_key_name" 
```

2. Execute the below
```console
$ terraform init
```
This would setup the backend for terraform to run. You should receive a **Terraform has been successfully initialized message**

3. (optional step) Execute the below
```console
$ terraform plan 
```
This command compiles the script and shows what all resources would be added or changed

4. Execute the below
```console
$ terraform apply 
```
This command would apply all the configuration in the script. When prompted type in ```Yes``` to confirm the execution.
Alternatively you can use ```$ terraform apply --auto-approve``` to skip the approval process. 


For **deleting the resources** created, execute ```$ terraform destroy``` 





