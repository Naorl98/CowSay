
# Cowsay-Naor Jenkins Pipeline

## Overview

This Jenkins pipeline is designed to automate the version control, Docker image creation, testing, and deployment processes for the Cowsay-Naor application. The pipeline facilitates continuous integration and deployment by leveraging AWS services, Docker containerization, and robust notification mechanisms.

## Pipeline Stages

- **Checkout Code**: Checks out the correct branch based on the specified release version, ensuring that the pipeline always works with the latest code.
- **Determine Version**: Dynamically calculates the next version number by incrementing the patch component and updates the version file in the repository.
- **Build Docker Image**: Constructs the Docker image and pushes it to AWS Elastic Container Registry (ECR) for storage.
- **E2E Tests**: Executes end-to-end tests by deploying the Docker container temporarily and verifying its operational status.
- **Deploy to EC2**: Deploys the Docker image to an Amazon EC2 instance, managing deployment logistics through SSH and AWS CLI commands.
- **Sanity Check**: After deployment, performs a sanity check by hitting the deployed application’s endpoint to ensure it responds correctly.
- **Cleanup and Tag Release**: Post-deployment, cleans up the environment and tags the release in Git for version tracking.

## Notifications

- **Success**: Upon successful build and deployment, sends an email to the developer and posts a success message to a configured webhook.
- **Failure**: In case of failure, sends a notification email detailing the issue and posts a failure alert to the webhook.

## Environment Variables

Here is a list of environment variables used in the pipeline:
- `AWS_ACCOUNT_ID`: AWS account ID for resource management.
- `AWS_REGION`: AWS region where resources are managed.
- `IMAGE_NAME`: Name of the Docker image.
- `REPO_NAME`: Name of the Docker repository.
- `ECR_URI`: URI of the AWS ECR.
- `EC2_INSTANCE_IP`: IP address of the target EC2 instance.
- `REMOTE_HOST`: Host for SSH connections.
- `ECR_REPO`: Full ECR repository path.
- `DEV_EMAIL`: Developer's email for notifications.
- `VERSION_FILE`: File containing the current application version.
- `BRANCH`: Git branch for checkout and deployment.

## Cleanup

Ensures all resources are properly cleaned up post-deployment to avoid unnecessary charges and clutter.

---

## Resume Summary for Cowsay-Naor Project

Designed and implemented a Jenkins CI/CD pipeline for the Cowsay-Naor application, integrating automated version handling, Docker operations, and AWS deployments. Optimized for efficiency and reliability, the pipeline significantly reduces manual errors and deployment times, ensuring robust deployment practices and continuous delivery.



<img width="357" alt="screen shot 2018-03-20 at 10 45 11 pm" src="https://user-images.githubusercontent.com/8520661/37696081-290403f0-2c91-11e8-9611-2ee8cbbfe877.png">

## Background
This is a minor re-write of [Cowsay Node](https://github.com/BibbyChung/cowsay-node) by Bibby Chung

It is adapted for course convenience.

Important note: Deepak Chopra is a quack.

## Features

1. show random "Deepak Chopra Quote".
2. put docker container to [bibbynet/cowsay-node](https://hub.docker.com/r/bibbynet/cowsay-node). 
 

## Build Container

```
docker build -t <YOUR CONTAINER NAME> .
```

## Run Container

```
docker run --rm -p 8080:8080 <YOUR CONTAINER NAME>
```

## docker-compose

```
version: "3.5"

services:
  cow-say: 
    build:
      context: ./
      dockerfile: ./Dockerfile
    ports:
      - 8080:8080
```

## docker-compose from Docker Hub

```
version: "3.5"

services:
  cow-say: 
    image: bibbynet/cowsay-node
    ports:
      - 8080:8080
```

## demo
https://cowsay-node.herokuapp.com/


Enjoy it. ^_____^ ..
