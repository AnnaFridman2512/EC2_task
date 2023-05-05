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
ELASTIC_IPS=()
for i in {0..2}; do
    ELASTIC_IP=$(aws ec2 allocate-address --domain vpc --query 'PublicIp' --output text)
    ELASTIC_IPS+=($ELASTIC_IP)
done

IMAGE_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query "Images[0].ImageId" --output text)

INSTANCE_TYPE=t3.micro

SUBNET_ID=$PUBLIC_SUBNET


INSTANCE_NAMES=("one" "two" "three")


for i in {0..2}; do

    INSTANCE_NAME=${INSTANCE_NAMES[i]}

    INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID --count 1 --instance-type $INSTANCE_TYPE --subnet-id $SUBNET_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' --output text)
    echo "Instance $INSTANCE_NAME created with ID: $INSTANCE_ID"

done


# Check if instances are running

    for INSTANCE_NAME in "${INSTANCE_NAMES[@]}"; do
        INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" --query 'Reservations[0].Instances[0].InstanceId' --output text)
        echo "Wait a minute for all instaces to run"
        sleep 30
        echo "Checking if all instances are running"
        INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text)
        if [ "$INSTANCE_STATE" = "running" ]; then
            #Add elastic IP 
            aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip ${ELASTIC_IPS[i]}
                # Stop instances one and two
            if [ "$INSTANCE_NAME" = "one" ] || [ "$INSTANCE_NAME" = "two" ]; then
                aws ec2 stop-instances --instance-ids $INSTANCE_ID
                #echo "Instance $INSTANCE_NAME stopped"
               
            fi
        else
            sleep 30
        fi
    done



echo "Instance status:"
echo "-----------------"
RUNNING_INSTANCES=0
STOPPED_INSTANCES=0
for i in {0..2}; do
    INSTANCE_NAME=${INSTANCE_NAMES[i]}
    INSTANCE_ID=${INSTANCE_IDS[i]}
    ELASTIC_IP=${ELASTIC_IPS[i]}
    INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].State.Name' --output text)
    if [ "$INSTANCE_STATE" = "running" ]; then
        echo "$INSTANCE_NAME is running with Elastic IP $ELASTIC_IP"
        RUNNING_INSTANCES=$((RUNNING_INSTANCES+1))
    else
        echo "$INSTANCE_NAME is stopped with Elastic IP $ELASTIC_IP"
        STOPPED_INSTANCES=$((STOPPED_INSTANCES+1))
    fi
done
echo "-----------------"
echo "Number of running instances: $RUNNING_INSTANCES"
echo "Number of stopped instances: $STOPPED_INSTANCES"