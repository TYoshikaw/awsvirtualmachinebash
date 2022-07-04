#!/bin/bash -e

# errexit -e: Exit the shell immediately if any command executed in the pipe or subshell results in an error
# You need to install the AWS Command Line Interface from http://aws.amazon.com/cli/
# Reference : https://github.com/AWSinAction/code2/tree/master/chapter04

# Get an Amazon Linux AMI ID
# Substitute appropriate values for "Values"
AMIID="$(aws ec2 describe-images --filters "Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0.20220606.1-x86_64-gp2" --query "Images[0].ImageId" --output text)"

# Get the default VPC ID
VPCID="$(aws ec2 describe-vpcs --filter "Name=isDefault, Values=true" --query "Vpcs[0].VpcId" --output text)"

# Get the ID of the default subnet
SUBNETID="$(aws ec2 describe-subnets --filters "Name=vpc-id, Values=$VPCID" --query "Subnets[0].SubnetId" --output text)"

# Create a security group
# Can enter an appropriate value for the security group name
SGID="$(aws ec2 create-security-group --group-name mysecuritygroup --description "My security group" --vpc-id "$VPCID" --output text)"

# Allow inbound SSH connections
aws ec2 authorize-security-group-ingress --group-id "$SGID" --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create and start a virtual machine
# Change the key name to an appropriate value
INSTANCEID="$(aws ec2 run-instances --image-id "$AMIID" --key-name mykey --instance-type t2.micro --security-group-ids "$SGID" --subnet-id "$SUBNETID" --query "Instances[0].InstanceId" --output text)"

echo "waiting for $INSTANCEID ..."

# Wait for the virtual machine to start
aws ec2 wait instance-running --instance-ids "$INSTANCEID"

# Get the public name of the virtual machine
PUBLICNAME="$(aws ec2 describe-instances --instance-ids "$INSTANCEID" --query "Reservations[0].Instances[0].PublicDnsName" --output text)"

echo "$INSTANCEID is accepting SSH connections under $PUBLICNAME"
echo "ssh -i mykey.pem ec2-user@$PUBLICNAME"

# -r : The -r option does not treat backslashes as escape characters
# -p : The -p option allows you to set the prompt characters to be displayed before typing when typing from the terminal with the read command
read -r -p "Press [Enter] key to terminate $INSTANCEID ..."

# Terminate the virtual machine
aws ec2 terminate-instances --instance-ids "$INSTANCEID"

echo "terminating $INSTANCEID ..."

# Wait for the virtual machine to terminate
aws ec2 wait instance-terminated --instance-ids "$INSTANCEID"

# Wait for the virtual machine to terminate
aws ec2 delete-security-group --group-id "$SGID"

echo "done."