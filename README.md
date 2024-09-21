# README

## Prerequisites

### Create Two Instances in N. Virginia (us-east-1) Region

#### Instance-1: WordPress Project Server
- **Server Configuration**: t2.micro with 8 GB volume
- **OS**: Ubuntu 22.04
- **Required Installations**: 
  - Git
  - Docker
  - Docker-compose
  - aws-cli

#### Instance-2: Jenkins-CICD Server
- **Server Configuration**: t2.micro with 8 GB volume
- **OS**: Ubuntu 22.04
- **Required Installations**:
  - Git
  - Docker
  - aws-cli
  - Java-17 (JDK & JRE)
  - Jenkins

### Setup ECR in N. Virginia (us-east-1) Region
- **Repository-1**: mysql (For MySQL image)
- **Repository-2**: wordpress (For WordPress image)

### Create an IAM Role to Access ECR
Attach this IAM role to both instances.

#### IAM Role Attached to Instance:
Example: `ECR_CustomRole`

#### Policy Attached with IAM Role (Required Permissions):
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:UploadLayerPart",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
```

## Instance-1: WordPress Project Server

### Step 1: Login to the Server

### Step 2: Install Required Software
Install all the required software mentioned in the prerequisites.

### Step 3: Clone the Git Repository
```bash
git clone https://github.com/BinitaPathak/Assessment-sigmaworld.git
```

### Step 4: Extract Required Files
1. **Dockerfile for MySQL Image**:
   - `Dockerfile.mysql`
   
2. **Dockerfile for Multistage WordPress Image**:
   - `Dockerfile.wordpress`
   
3. **Docker Compose File**:
   - `docker-compose.yml` (to run the container from the customized image in ECR repository)
   
4. **Script to Deploy Docker Compose**:
   - `run-docker-compose.sh`
   
5. **Environment File**:
   - `.env`

#### Set Permissions for the .env File
```bash
chmod 600 .env
```

### Step 5: Security Group for WordPress Server

| Name                 | Security Group Rule ID | Port Range | Protocol | Source             | Description                  |
|----------------------|------------------------|------------|----------|---------------------|------------------------------|
| SG_wordpressproject | sgr-0255ec7e78deb8a75  | 8080       | TCP      | 152.59.47.144/32    | To access docker application |
| SG_wordpressproject | sgr-0bdbfdb8216c4a010  | 22         | TCP      | 172.31.91.63/32     | Private IP (Jenkins server)  |
| SG_wordpressproject | sgr-0c6fbe6ca280fe140  | 22         | TCP      | 152.59.47.144/32    | To SSH into WordPress server |

## Instance-2: Jenkins-CICD Server

### Step 1: Login to the Server

### Step 2: Install Required Software
Install all the required software mentioned in the prerequisites.

### Step 3: Security Group for Jenkins CICD

| Security Group Rule ID | IP Version | Type        | Protocol | Port Range | Source             | Description               |
|------------------------|------------|-------------|----------|------------|---------------------|---------------------------|
| sgr-09674e72012f6aabe  | IPv4       | SMTPS       | TCP      | 465        | 152.59.47.144/32    | To access Gmail server    |
| sgr-08645d9780f5849b5  | IPv4       | SSH         | TCP      | 22         | 152.59.47.144/32    | To Login                  |
| sgr-08de84dcc98f4f1a9  | IPv4       | Custom TCP  | TCP      | 8080       | 152.59.47.144/32    | To access Jenkins server  |

### Step 4: Setup Credentials for CI/CD

**Path To Setup Credentials:** Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials
1. **Setup Credentials for Git**
2. **Setup Credential to SSH into WordPress Server**
3. **Setup Credentials for Email Notification**

#### Process to Setup Git Credentials:
- Select: Username with password
- Scope: Global (Jenkins, nodes, items, all child items, etc)
- Username: #Add GitHub username
- Password: #Add GitHub Token
- ID: `Gitid`

#### Process to Setup Plugin and Credential to SSH into WordPress Server:
1. Install Plugin:
   - Go to Dashboard -> Manage Jenkins -> Plugins
   - Install SSH Agent Plugin

2. Setup Password-less Authentication Between Servers (Jenkins & WordPress):
   - Generate SSH Key Pair on Jenkins Machine:
     ```bash
     ssh-keygen -t rsa -b 4096 -C "jenkins"
     ```
   - Copy the contents of `~/.ssh/id_rsa.pub` and append them to `~/.ssh/authorized_keys` file of the WordPress user on the remote server
     ```bash
     cat ~/.ssh/id_rsa.pub
     ssh wordpress@<remote_server_ip>
     mkdir -p ~/.ssh
     vi ~/.ssh/authorized_keys
     ```

3. Add Private Key in SSH Agent Credentials:
   - Go to Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials
   - Select Username with Private Key credential
   - Scope: Global (Jenkins, nodes, items, all child items, etc)
   - ID: `ssh-agent`
   - Username: #Add WordPress Server User
   - Private Key: #Paste contents of `~/.ssh/id_rsa` (the private key from Jenkins machine)

#### Setup Credentials for Email Notification:
> Note: Make sure to generate App password from Gmail & Two-Factor authentication is required.

1. Go to Dashboard -> Manage Jenkins -> Credentials -> System -> Global credentials
2. Select Username with password
3. Scope: Global (Jenkins, nodes, items, all child items, etc)
4. Username: #Add Gmail ID
5. Password: #Add Generated App Password
6. ID: `mail-Cred`

#### Configure Email Notification:
1. Go to Dashboard -> Manage Jenkins -> System
2. Scroll down to Extended E-mail Notification and add details:
   - SMTP server: smtp.gmail.com
   - SMTP Port: 465
   
3. Scroll Down to E-mail Notification
   ```
   SMTP server: smtp.gmail.com
   Use SMTP Authentication
   User Name: ADD Email ID
   Password: Add App Password
   Use SSL: Check
   SMTP Port: 465
   Charset: UTF-8
   ```

4. Test configuration by sending test e-mail
5. Click on Advanced and add credentials set up in email notification
6. Enable SSL and fill out SMTP details
7. Click on Save button

### Step 5: Steps to Create Parameterized Pipeline for Project

1. Click on New Item and add pipeline name
2. Select item type as Pipeline and click OK button
3. Check the box for "This project is parameterized"
4. Select string parameter for all variables and add default values:
   ```
   AWS_REGION: us-east-1
   DOCKER_TAG: v1
   ACCOUNTID: # example 1234567890
   GIT_BRANCH: main
   GIT_URL: https://github.com/BinitaPathak/Assessment-sigmaworld
   EMAIL_INFORM: your-email@example.com
   ```
5. Pipeline Script: Get the script from GitHub and paste its content in the pipeline definition (file name: `pipeline-script`)
6. Save changes and click on **Build with Parameters** to run the pipeline

### Explaining Each Stage of CICD Pipeline

- **STAGE-1**: Clean the workspace before starting the build
- **STAGE-2**: Checkout code from GitHub repository
- **STAGE-3**: List content of the Git repository
- **STAGE-4**: Build Docker Image for WordPress and MySQL
- **STAGE-5**: Retag Docker Image for ECR repository
- **STAGE-6**: Push Docker Image to ECR
- **STAGE-7**: SSH Agent connects to WordPress server from Jenkins
- **STAGE-8**: Test WordPress Home Page (commented out due to domain/network connectivity requirements)
- **STAGE-9**: Email Notification for build execution

---
