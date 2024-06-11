# Installing Terraform

https://developer.hashicorp.com/terraform/install

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform

# Documentation

Terraform is well documented at https://registry.terraform.io/
Finding providers and how to use them is very easy. Even over Google you'll find results fast.

# Using Terraform with AWS

We need to use the aws provider and look up how to configure it
It requires the Access Key and Secret Key. This secret information must be stored in a secret and not plain text.
Also the aws provider must be downloaded through being configured in providers.tf and 

    terraform init

Official providers must not be defined in providers.tf, but its good practise.



# 4 - Resources & Data Sources

Previously the secret key and access key were defined within Terraform.
This seems to make problems with specific characters within those values.
Setting them instead through environment variables works.

Resources are used to create resources for example in the cloud.

Data Sources are used to load data from existing resources e.g. a VPC-ID by the default flag.

# 5 - Change & Destroy Terraform Resources

Use the command to apply the desired state (main.tf) to the AWS account

    terraform apply

Changes, Updates, Deletes are made through the file

    terraform apply

or

    terraform plan

show the changes that are being done.

Deletion through other commands is possible, but the best practise is to do it within the .tf file as this way the desired state is always documented.

    terraform destroy -target aws_subnet.dev-subnet-2

# 6 - Terraform commands

No approve necessary with command

    terraform apply -auto-approve

Delete/cleanup the complete infrastructure
    
    terraform destroy

# 7 - Terraform state

The terraform state can be view in the terraform.tfstate file, but if the infrastructure is getting bigger it's hardly readable.
There a command to show and list the state does exist.

    terraform state
    terraform state list
    terraform state show <name>

Within the terraform.tfstate.backup the previous state is stored.

# 8 - Output Values

Is used to output generated ids to console after the state was applied.

# 9 - Variables in Terraform

Multiple variables can be defined with different types like a string or list or a list of objects or whatever.
Variables can be passed through -var "<varname>=<varvalue>" or through a .tfvars file. Manual input is also possible for testing.
The terraform.tfvars file is automatically detected, if another name is used for seperation like -dev, -prod, ... the file must be named through -var-file 

    terraform apply -var-file terraform-dev.tfvars