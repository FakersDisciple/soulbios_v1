#!/usr/bin/env python3
"""
AWS Deployment Configuration for SoulBios Backend
Handles EC2 deployment, SSL setup, and monitoring configuration
"""

import os
import boto3
import json
import logging
from typing import Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

class AWSDeploymentManager:
    """
    Manages AWS deployment for SoulBios backend
    """
    
    def __init__(self):
        self.ec2_client = boto3.client('ec2')
        self.secrets_client = boto3.client('secretsmanager')
        self.cloudwatch_client = boto3.client('cloudwatch')
        self.s3_client = boto3.client('s3')
        
        # Deployment configuration
        self.deployment_config = {
            "instance_type": "t3.medium",
            "ami_id": "ami-0c02fb55956c7d316",  # Amazon Linux 2 AMI
            "security_group_name": "soulbios-backend-sg",
            "key_pair_name": "soulbios-backend-key",
            "domain_name": "api.soulbios.app",
            "ssl_certificate_arn": None,  # Will be set after ACM certificate creation
            "s3_bucket": "soulbios-staging-builds"
        }
    
    def create_security_group(self) -> str:
        """Create security group for backend EC2 instance"""
        
        try:
            # Check if security group already exists
            response = self.ec2_client.describe_security_groups(
                GroupNames=[self.deployment_config["security_group_name"]]
            )
            sg_id = response['SecurityGroups'][0]['GroupId']
            logging.info(f"Using existing security group: {sg_id}")
            return sg_id
            
        except self.ec2_client.exceptions.ClientError:
            # Create new security group
            response = self.ec2_client.create_security_group(
                GroupName=self.deployment_config["security_group_name"],
                Description='Security group for SoulBios backend API'
            )
            sg_id = response['GroupId']
            
            # Add inbound rules
            self.ec2_client.authorize_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=[
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': 80,
                        'ToPort': 80,
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    },
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': 443,
                        'ToPort': 443,
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    },
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': 8000,
                        'ToPort': 8000,
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    },
                    {
                        'IpProtocol': 'tcp',
                        'FromPort': 22,
                        'ToPort': 22,
                        'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                    }
                ]
            )
            
            logging.info(f"Created security group: {sg_id}")
            return sg_id
    
    def create_s3_bucket(self) -> str:
        """Create S3 bucket for staging builds"""
        
        bucket_name = self.deployment_config["s3_bucket"]
        
        try:
            # Check if bucket exists
            self.s3_client.head_bucket(Bucket=bucket_name)
            logging.info(f"Using existing S3 bucket: {bucket_name}")
            
        except self.s3_client.exceptions.ClientError:
            # Create bucket
            self.s3_client.create_bucket(Bucket=bucket_name)
            
            # Enable versioning
            self.s3_client.put_bucket_versioning(
                Bucket=bucket_name,
                VersioningConfiguration={'Status': 'Enabled'}
            )
            
            # Set public read policy for staging builds
            bucket_policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "PublicReadGetObject",
                        "Effect": "Allow",
                        "Principal": "*",
                        "Action": "s3:GetObject",
                        "Resource": f"arn:aws:s3:::{bucket_name}/staging/*"
                    }
                ]
            }
            
            self.s3_client.put_bucket_policy(
                Bucket=bucket_name,
                Policy=json.dumps(bucket_policy)
            )
            
            logging.info(f"Created S3 bucket: {bucket_name}")
        
        return bucket_name
    
    def setup_secrets_manager(self) -> Dict[str, str]:
        """Setup AWS Secrets Manager for API keys"""
        
        secrets = {}
        
        # Create Gemini API key secret
        try:
            response = self.secrets_client.create_secret(
                Name='SoulBios/GeminiKey',
                Description='Gemini API key for SoulBios backend',
                SecretString=json.dumps({
                    'GEMINI_API_KEY': 'your-gemini-api-key-here'
                })
            )
            secrets['gemini_secret_arn'] = response['ARN']
            logging.info("Created Gemini API key secret")
            
        except self.secrets_client.exceptions.ResourceExistsException:
            # Secret already exists
            response = self.secrets_client.describe_secret(SecretId='SoulBios/GeminiKey')
            secrets['gemini_secret_arn'] = response['ARN']
            logging.info("Using existing Gemini API key secret")
        
        return secrets
    
    def create_cloudwatch_alarms(self) -> None:
        """Create CloudWatch alarms for monitoring"""
        
        alarms = [
            {
                'AlarmName': 'SoulBios-API-HighLatency',
                'ComparisonOperator': 'GreaterThanThreshold',
                'EvaluationPeriods': 2,
                'MetricName': 'Duration',
                'Namespace': 'AWS/ApplicationELB',
                'Period': 300,
                'Statistic': 'Average',
                'Threshold': 500.0,
                'ActionsEnabled': True,
                'AlarmDescription': 'API response time exceeds 500ms',
                'Unit': 'Milliseconds'
            },
            {
                'AlarmName': 'SoulBios-API-ErrorRate',
                'ComparisonOperator': 'GreaterThanThreshold',
                'EvaluationPeriods': 2,
                'MetricName': 'HTTPCode_Target_5XX_Count',
                'Namespace': 'AWS/ApplicationELB',
                'Period': 300,
                'Statistic': 'Sum',
                'Threshold': 10.0,
                'ActionsEnabled': True,
                'AlarmDescription': 'High error rate detected'
            }
        ]
        
        for alarm in alarms:
            try:
                self.cloudwatch_client.put_metric_alarm(**alarm)
                logging.info(f"Created CloudWatch alarm: {alarm['AlarmName']}")
            except Exception as e:
                logging.warning(f"Failed to create alarm {alarm['AlarmName']}: {e}")
    
    def generate_user_data_script(self) -> str:
        """Generate EC2 user data script for backend deployment"""
        
        return """#!/bin/bash
# SoulBios Backend Deployment Script

# Update system
yum update -y

# Install Python 3.9 and pip
yum install -y python3 python3-pip git nginx

# Install AWS CLI
pip3 install awscli

# Create application directory
mkdir -p /opt/soulbios
cd /opt/soulbios

# Clone repository (replace with your repo URL)
# git clone https://github.com/your-org/soulbios-backend.git .

# For now, we'll create the deployment structure
mkdir -p deepconf logs

# Install Python dependencies
pip3 install -r deepconf/requirements.txt

# Get secrets from AWS Secrets Manager
export GEMINI_API_KEY=$(aws secretsmanager get-secret-value --secret-id SoulBios/GeminiKey --query SecretString --output text | jq -r .GEMINI_API_KEY)

# Create systemd service
cat > /etc/systemd/system/soulbios.service << EOF
[Unit]
Description=SoulBios FastAPI Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/soulbios
Environment=GEMINI_API_KEY=$GEMINI_API_KEY
Environment=ENVIRONMENT=production
ExecStart=/usr/bin/python3 -m uvicorn deepconf.soulbios_api:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Configure nginx
cat > /etc/nginx/conf.d/soulbios.conf << EOF
server {
    listen 80;
    server_name api.soulbios.app;
    
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Start services
systemctl enable nginx
systemctl start nginx
systemctl enable soulbios
systemctl start soulbios

# Setup log rotation
cat > /etc/logrotate.d/soulbios << EOF
/opt/soulbios/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 ec2-user ec2-user
}
EOF
"""
    
    def deploy_infrastructure(self) -> Dict[str, Any]:
        """Deploy complete AWS infrastructure"""
        
        logging.info("Starting AWS infrastructure deployment...")
        
        # Create security group
        sg_id = self.create_security_group()
        
        # Create S3 bucket
        bucket_name = self.create_s3_bucket()
        
        # Setup secrets
        secrets = self.setup_secrets_manager()
        
        # Create CloudWatch alarms
        self.create_cloudwatch_alarms()
        
        deployment_info = {
            "security_group_id": sg_id,
            "s3_bucket": bucket_name,
            "secrets": secrets,
            "user_data_script": self.generate_user_data_script(),
            "deployment_config": self.deployment_config
        }
        
        logging.info("AWS infrastructure deployment completed!")
        return deployment_info


if __name__ == "__main__":
    # Test deployment manager
    try:
        manager = AWSDeploymentManager()
        result = manager.deploy_infrastructure()
        
        print("Deployment Configuration:")
        print("=" * 50)
        print(f"Security Group ID: {result['security_group_id']}")
        print(f"S3 Bucket: {result['s3_bucket']}")
        print(f"Secrets: {result['secrets']}")
        print("\nNext steps:")
        print("1. Launch EC2 instance with the generated user data script")
        print("2. Configure SSL certificate with AWS Certificate Manager")
        print("3. Set up Application Load Balancer")
        print("4. Update Flutter app with production API URL")
        
    except Exception as e:
        print(f"Deployment failed: {e}")
        import traceback
        traceback.print_exc()