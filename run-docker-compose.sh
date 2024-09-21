#!/bin/bash

# Define the environment file
ENV_FILE=".env"

# Check if the environment file exists
if [ ! -f $ENV_FILE ]; then
  echo "$ENV_FILE file not found!"
  exit 1
fi

# Load the environment variables
export $(grep -v '^#' $ENV_FILE | xargs)

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 597088056986.dkr.ecr.us-east-1.amazonaws.com

# Check if the login was successful
if [ $? -ne 0 ]; then
  echo "ECR login failed!"
  exit 1
fi

# Pull the latest images
#echo "Pulling latest Docker images..."
#docker-compose pull
# STOP Docker Compose
#echo "Stop Docker Compose..."
#docker-compose --env-file $ENV_FILE down
if [ "$(docker-compose --env-file $ENV_FILE ps -q)" ]; then
  echo "Containers are already running. Stopping and removing existing containers..."
  docker-compose --env-file $ENV_FILE down
else
  echo "No containers are currently running."
fi

sleep 10

# Run Docker Compose
echo "Starting Docker Compose..."
docker-compose --env-file $ENV_FILE up -d

# Check if the Docker Compose command was successful
if [ $? -eq 0 ]; then
  echo "Docker Compose ran successfully."
else
  echo "Docker Compose failed to start."
  exit 1
fi

