#!/bin/bash

# Read AWS credentials from file
AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

# Get default VPC ID
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[?IsDefault].VpcId' --output text)
#echo $VPC_ID

# Get first public subnet ID in the VPC
PUBLIC_SUBNET=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC_ID Name=map-public-ip-on-launch,Values=true --query 'Subnets[0].SubnetId' --output text)

#echo "Public subnet is: $PUBLIC_SUBNET"

IMAGE_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images[0].ImageId" --output text)

INSTANCE_TYPE=t3.micro

SUBNET_ID=$PUBLIC_SUBNET

INSTANCE_NAMES=("one" "two" "three")


for i in {0..2}; do

    INSTANCE_NAME=${INSTANCE_NAMES[i]}

    #INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE  --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
    INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE --subnet-id $SUBNET_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' --output text)
    echo "Instance $INSTANCE_NAME created with ID: $INSTANCE_ID"

 

    #echo "Instance $i created: $INSTANCE_ID"
done
