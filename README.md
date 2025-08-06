# How to Provision and Deploy the Project

This project automates the provisioning of infrastructure, building the application, and deploying it using Ansible. Below is a step-by-step guide to understand the flow and usage.

---

## Prerequisites
Ensure the following tools are installed on your system:
1. **Terraform** >= 1.5.0 - For provisioning infrastructure.
2. **Ansible** - For configuration management and deployment.
3. **Make** - To simplify running commands.
4. **jq** - For processing JSON outputs.

---

## Flow Overview

### 1. Provision Infrastructure
The infrastructure is provisioned using Terraform. This includes creating resources such as VPCs, subnets, EC2 instances, and other necessary components. Terraform ensures the infrastructure is defined as code and can be easily managed and replicated.

### 2. Build the Application
Once the infrastructure is provisioned, the application is built. This step involves packaging the application code into a deployable artifact (e.g., a Docker image or binary). The build process is automated using `Make`.

### 3. Deploy with Ansible
After the application is built, Ansible is used to configure the provisioned servers and deploy the application. Ansible ensures the servers are properly configured and the application is deployed in a consistent and repeatable manner.


## Architecture Flow Diagram
```
+-----------------------------+
|        DevOps guy          |
|  (run Makefile commands)   |
+-------------+--------------+
              |
              v
+-------------+--------------+
|       Terraform CLI        |
|    (infra provisioning)    |
+-------------+--------------+
              |
              v
+-------------+--------------+
|        AWS EC2             |
| (instances + security + key)
+-------------+--------------+
              |
              v
+-------------+--------------+
|         Ansible            |
| (ssh, install docker, run) |
+-------------+--------------+
              |
              v
+-------------+--------------+
|     Docker on EC2          |
| (pull image from ECR, run) |
+-----------------------------+
```

## Usage

### Deploy All
To provision the infrastructure, build the application, and deploy it, run the following command:
```bash
make all IMAGE_TAG=<version>
```

### Update and Redeploy Latency application
```bash
make update-app IMAGE_TAG=<new-tag>
```

# Technology choices and rationale
## Docker - Application Packaging & Portability
- Why: Docker allows your Python application to be packaged with all its dependencies, ensuring consistency across environments.

- Benefits: 
    - Eliminates “it works on my machine” issues.
    - Simplifies deploym- ent (just pull and run the container).
    - Integrates easily - with CI/CD and ECR (AWS container registry).

- Role in this project: Build a container image of the latency-monitor app and push it to ECR for remote deployment.

## Terraform – Infrastructure as Code (IaC)
- Why: Terraform lets you define and manage your entire infrastructure (VPCs, subnets, EC2, key pairs, etc.) in a declarative, version-controlled way.

- Benefits:

    - Repeatable, consistent provisioning across environments.
    - Integrates with many providers (AWS, GCP, etc.).
    - State management and plan-preview make infrastructure safer to manage.

- Role in this project: Provision EC2 instances and networking resources where the Dockerized app will be deployed.

## Ansible – Configuration & Application Deployment
- Why: Ansible is a simple, agentless tool used to automate configuration and app deployment over SSH.

- Benefits:
    - No need to install agents on EC2.
    - YAML-based playbooks are easy to read and reuse.
    - Can manage multiple hosts in parallel.

- Role in this project:
    - SSH into EC2, install Docker (only once).
    - Login to AWS ECR.
    - Pull the image and run the container.

## Combined Architecture Rationale
| Layer          | Tool          | Responsibility                        |
| -------------- | ------------- | ------------------------------------- |
| Infrastructure | **Terraform** | Provision EC2 and networking          |
| Configuration  | **Ansible**   | SSH setup, install Docker, deploy app |
| Application    | **Docker**    | Package and run the Python app        |


# How to access and interpret the latency metrics
## 1. Access
### a. Ensure the application is running
- SSH EC2 to check Docker container is running
    ```bash
    ssh -i terraform/keys/id_rsa ubuntu@<ec2-public-ip>
    docker ps -a
    ```
### b. Access the /latency Endpoint
#### Option 1: Using CURL
```bash
### Default host 
curl http://<ec2-public-ip>:5000/latency

### Specific host
curl http://<ec2-public-ip>:5000/latency?host=google.com
```
#### Option 2: Using Browser
Navigate to
```bash
### Default host 
http://<ec2-public-ip>:5000/latency

### Specific host
http://<ec2-public-ip>:5000/latency?host=google.com
```

## 2. Interpret the Latency Metrics
### JSON Response
```json
{
    "host": "10.100.5.15",
    "timestamp": "2025-08-06 16:55:45 +07",
    "status": "reachable",
    "average_latency_ms": 14.20,
}
```
### 1. **"host"**
- Description: The hostname or IP address pinged (e.g., 8.8.8.8 or google.com).
- Interpretation: Confirms the target you’re measuring latency for. If set via PING_HOST (e.g., export PING_HOST=8.8.8.8), it reflects that value unless overridden by the host query parameter.
- Use: Ensure the correct target is being tested. For example, 8.8.8.8 (Google’s DNS) is a reliable public server for benchmarking.

### 2. **"timestamp"**
- Description: The date and time the ping was performed, in the format YYYY-MM-DD HH:MM:SS +TZ (e.g., 2025-08-06 16:55:45 +07).
- Interpretation: Indicates when the measurement was taken, useful for tracking latency over time. The +07 reflects the timezone (ICT, typical for ap-southeast-1).
- Use: Correlate latency with specific times to identify patterns (e.g., network congestion during peak hours).

### 3. **"status"**
- Description: Indicates if the host was reachable (reachable) or not (unreachable).
- Interpretation:
    - reachable: All ping packets received responses, indicating the host is online and accessible.
    - unreachable: Ping failed (e.g., host down, network blocked, or timeout). Check the details field for the error (e.g., “Destination Host Unreachable” or “Request timed out”).

- Use: Quickly assess network connectivity. If unreachable, verify the host exists, check EC2 security group outbound ICMP rules, or test a different host.

### 4. **"average_latency_ms"**

- Description: The average round-trip time (RTT) in milliseconds for the ping requests (e.g., 14.20 ms).
- Interpretation:

    - Low Latency (< 20 ms): Excellent network performance, typical for nearby servers or high-quality connections.
    - Moderate Latency (20–50 ms): Acceptable for most applications, common for cross-region or international connections.
    - High Latency (> 50 ms): May indicate network congestion, distant servers, or issues like packet loss.
    - Null Value: If null, the ping failed or the latency couldn’t be parsed (check details for errors).

- Use: Measure network performance. For example, 14.20 ms to 8.8.8.8 from ap-southeast-1 suggests a fast, reliable connection to Google’s DNS.

# Any assumptions, limitations, or tradeoffs
## Assumptions
### 1. AWS Environment
- You already have an AWS account with permission to create resources such as EC2, VPC, ECR, IAM, etc.
- AWS CLI is properly configured (aws configure is already done).
### 2. Application Image
- The latency-app Docker image is assumed to be built successfully.
- The image must be pushed to ECR before deployment with Ansible.

## Limitations
### 1. No Load Balancer / High Availability
- There’s no Elastic Load Balancer or Auto Scaling Group configured.
### 2. Static Ansible Inventory
- The inventory file is generated from Terraform output, manually or by script.
- No use of Ansible dynamic inventory plugins.
### 3. Public EC2 Instances Only
- All EC2 instances are in public subnets.
- This exposes them directly to the internet, which may be insecure without strong security group rules.
### 4. Secrets Handling
- The SSH private key is written locally without encryption. Although we have **.gitignore** to avoid push the key to Github.

## Tradeoffs
| Trade-off                      | Why it was chosen                     | Consequences                                   |
| ------------------------------ | ------------------------------------- | ---------------------------------------------- |
| **Terraform Modules**          | For modularity and reusability        | Slightly more complex for minor customizations |
| **Ansible for App Deployment** | Fine-grained control over app setup   | Requires SSH key and public IPs                |
| **Dockerized Application**     | Makes the app portable and consistent | Docker must be installed on EC2                |
| **Static Inventory**           | Simpler, avoids plugin setup          | Cannot auto-scale or dynamically adjust        |
| **Public EC2 + SG**            | Easier to SSH and deploy              | Security risk if IP ranges aren't restricted   |

# Optional Reflection
## Sources of observed latency
- Since the ping uses public IPs, packets must travel through the public internet, traversing multiple hops and ISPs, adding unpredictable latency.
- Even within the same region, if instances are in different Availability Zones, latency might slightly increase due to physical separation.

## Ideas to improve latency, precision or consistency
- Use Private IPs Instead of Public
- Dedicated Monitoring Agents: Install lightweight agents (e.g., Telegraf, Prometheus Node Exporter) to collect consistent latency metrics over time.

## What you would do differently in a production setup
To make the system production-ready, consider:
- Private Network Communication: Switch to VPC-internal communication via private IP. It's faster, cheaper, and more secure.
- Deploy in the Same AZ (if needed): For ultra-low latency systems (e.g., trading), co-locate instances in the same Availability Zone or even same placement group.
- Secure Access & Authentication: Lock down instance access and restrict public exposure. Use IAM roles, VPC security groups, and bastion hosts for admin access.
- Replacing SSH key access with IAM roles for EC2.
- Using dynamic Ansible inventory (via AWS plugin).
- Add Retry & Timeout Logic.