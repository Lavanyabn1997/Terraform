Terraform 
It is an open-source tool by HashiCorp used for Infrastructure as Code (IaC).
Instead of manually setting up servers, networks, and cloud services,
you define your infrastructure in configuration files, 
Terraform automatically provisions and manages it.
Define infrastructure in code (using HCL – HashiCorp Configuration Language)

Key Features

Infrastructure as Code (IaC) - You write declarative configuration files to describe your desired infrastructure state.
Multi-Cloud Support - Terraform works across multiple providers, so you’re not locked into one cloud.
Execution Plan - Before making changes, Terraform shows a preview (terraform plan) of what will happen.
State Management - It keeps track of your infrastructure state in a state file.
Modular Architecture - Reusable modules help organize and scale infrastructure.
Dependency Graph - Terraform automatically understands dependencies between resources and applies them in the correct order.

Advantages

Automation & Efficiency - Reduces manual setup and human error.
Consistency - Same configuration = same infrastructure every time.
Version Control - You can store Terraform code in Git and track changes.
Multi-Cloud Flexibility - Manage different providers in one tool.
Scalable & Reusable - Modules allow reuse across projects.

Disadvantages

State File Complexity - Managing the Terraform state file can be tricky, especially in teams.
Learning Curve - HCL and Terraform concepts may take time to understand for beginners.
Limited Real-Time Awareness - Terraform doesn’t automatically detect changes made outside of it (called “drift”) unless you run commands.
Debugging Can Be Hard - Errors can sometimes be unclear or difficult to troubleshoot.
Not Ideal for Configuration Management - Terraform is for provisioning infrastructure, not configuring software inside servers (tools like Ansible or Puppet are better for that).

Declarative Vs Imperative Approaches

| **Feature**          | **Declarative Approach**                                                                   | **Imperative Approach**                                                        |
| -------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| **Philosophy**       | Specifies the desired state (the "what") of the infrastructure.                            | Details the exact steps or commands (the "how") to achieve the desired state.  |
| **Execution**        | The IaC tool determines and performs the actions needed to reach the desired state.        | Requires the user to execute commands in the correct sequence.                 |
| **State Management** | The tool tracks the current state of the infrastructure, simplifying updates and teardown. | Does not inherently track state; the user is responsible for managing changes. |
| **User Focus**       | Simplifies the process; users define what they want.                                       | Demands detailed instructions; the user defines how to achieve the result.     |
| **Handling Changes** | Automatically calculates and applies the necessary changes to match the new desired state. | The user must write a new script to figure out and apply the changes manually. |
| **Example**          | Terraform config: `                                                                        |                                                                                |

Terraform vs AWS CloudFormation

| **Feature**  | **Terraform**                                                                            | **AWS CloudFormation**                                 |
| ------------ | ---------------------------------------------------------------------------------------- | ------------------------------------------------------ |
| **Scope**    | Multi-cloud (supports Amazon Web Services, Microsoft Azure, Google Cloud Platform, etc.) | AWS only (tightly integrated with Amazon Web Services) |
| **Language** | HCL (HashiCorp Configuration Language – simple, clean, easy to read)                     | JSON or YAML (can become verbose and complex)          |
| **State**    | Managed by user (local or remote state management)                                       | Managed automatically by Amazon Web Services           |

Terraform vs Ansible

| **Feature**       | **Terraform**                                                                                         | **Ansible**                                                                               |
| ----------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **Primary Use**   | Focuses on setting up and managing infrastructure.                                                    | Primarily used for configuring systems and deploying applications.                        |
| **Language**      | Uses HCL for infrastructure definitions.                                                              | Uses YAML for defining tasks.                                                             |
| **Stability**     | Automatically ensures resources are created only if necessary (idempotent infrastructure management). | Requires careful task definition to avoid duplication in execution.                       |
| **Execution**     | Manages infrastructure changes using execution plans and state tracking.                              | Executes tasks immediately without persistent state tracking.                             |
| **Cloud Support** | Excellent multi-cloud capabilities (AWS, Azure, GCP, etc.).                                           | Supports multi-cloud environments but mainly focused on system-level configuration tasks. |

Terraform Work Flow:

1. Write Configuration (Define Infrastructure)
You create .tf files using HCL (HashiCorp Configuration Language)
You define what infrastructure you want

Example:

EC2 instance
Virtual network
Database

This is the desired state

2. Initialize Terraform
terraform init

What happens:

Downloads required providers (e.g., Amazon Web Services, Microsoft Azure)
Sets up backend configuration (state storage)
Prepares working directory

3. Plan the Changes
terraform plan

What happens:

Compares current state vs desired state
Creates an execution plan

Shows:
What will be created
What will be changed
What will be deleted

Safe preview step (no changes applied)

4. Apply the Changes
terraform apply

What happens:

Executes the plan
Calls cloud provider APIs
Creates/updates/deletes resources
Updates the state file
5. State Management
Terraform maintains a state file (terraform.tfstate)
Tracks real infrastructure
Helps detect drift (manual changes outside Terraform)
6. Destroy Infrastructure (Optional)
terraform destroy

What happens:

Deletes all resources defined in configuration
Cleans up infrastructure completely

Terraform Workflow Diagram

Write Code (.tf files)
        ↓
terraform init
        ↓
terraform plan
        ↓
terraform apply
        ↓
Cloud Infrastructure Created (AWS / Azure / GCP)
        ↓
State File Updated

Simple Explanation

Think of Terraform workflow like this:

Write → describe what you want
Init → prepare tools
Plan → preview changes
Apply → build infrastructure
State → remember everything

Providers and Resources in Terraform

In Terraform (from HashiCorp), providers and resources are the two most important building blocks. 
They define where infrastructure is created and what is created.

Providers in Terraform

A provider is a plugin that allows Terraform to interact with an external platform (cloud or service).
It acts as a bridge between Terraform and cloud platforms.

What Provider Does:
A provider Connects Terraform to a cloud or service,Exposes APIs as resources,Handles authentication,Manages lifecycle of infrastructure

Without a provider, Terraform cannot create anything.

Resources in Terraform
A resource is a component of infrastructure that Terraform manages.It is the actual object created in the cloud.
Eg:
Virtual machine
Database
Network
Storage bucket

Provider = where to create
Resource = what to create

| Feature  | Provider                         | Resource                     |
| -------- | -------------------------------- | ---------------------------- |
| Meaning  | Connects Terraform to a platform | Actual infrastructure object |
| Role     | Bridge / API connector           | Real cloud object            |
| Example  | AWS, Azure, GCP                  | EC2, VM, S3 bucket           |
| Quantity | Usually few per project          | Many resources per project   |


Terraform Modules:
In Terraform (from HashiCorp), a module is a reusable container for a set of infrastructure resources. 
It helps you organize, reuse, and manage your Terraform code efficiently.

A module is simply a folder containing.tf files (resource definitions),input variables and output values

Advantages of Modules
 Reusability (write once, use many times)
 Cleaner code structure
 Easier team collaboration
 Standardized infrastructure design
 Faster deployment
 
Disadvantages of Modules
 Learning curve for beginners
 Debugging can be harder in nested modules
 Dependency complexity in large projects
 Over-modularization can make projects harder to follow

Types of Modules
1. Root Module
The main working directory where you run Terraform commands
Every Terraform project has one root module

2. Child Modules
Reusable modules called inside the root module
Can be local or from remote sources

Example sources:

Local directory
GitHub
Terraform Registry

Why Use Modules?
Modules help you:

Avoid code duplication
Improve reusability
Organize large infrastructure projects
Standardize environments (dev, test, prod)

Modules Project Structure :

project/
│
├── main.tf
├── variables.tf
├── outputs.tf
│
└── modules/
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
		
How Modules Works:

Root Module
     ↓
Calls Child Module
     ↓
Module creates resources
     ↓
Cloud Provider (AWS/Azure/GCP)
     ↓
Infrastructure is provisioned

Terraform Variables
n Terraform (from HashiCorp), variables are used to make your infrastructure code flexible and reusable.
Instead of hardcoding values (like instance types, regions, or AMI IDs),
you define variables and pass values dynamically.

A variable is a placeholder for a value that can be passed into a Terraform configuration.It helps you avoid repeating or hardcoding values.

Why Use Variables?

Make code reusable
Avoid hardcoding sensitive or changing values
Support multiple environments (dev, test, prod)
Improve readability and maintainability

Types of Terraform Variables:

1. Input Variables

Used to pass values into Terraform configurations.

2. Output Variables

Used to display or export values after infrastructure is created.

3. Local Variables

Used for intermediate values inside configuration.

Ways to Assign Variable Values

1. Default Value (inside variable block)
default = "t2.micro"
2. Command Line
terraform apply -var="instance_type=t2.small"
3. Variable File (terraform.tfvars)
instance_type = "t2.micro"
4. Environment Variables
export TF_VAR_instance_type=t2.micro

Terraform Variable Types

In Terraform (from HashiCorp), variables can have different data types. These types define what kind of value a variable can store.

| Type   | Structure          | Example              | Use Case                 |
| ------ | ------------------ | -------------------- | ------------------------ |
| String | Single value       | `"t2.micro"`         | Names, IDs, regions      |
| List   | Ordered collection | `["a", "b"]`         | Multiple values like AZs |
| Map    | Key-value pairs    | `{Env="Dev"}`        | Tags, settings           |
| Object | Structured data    | `{type, ami, count}` | Complex configs          |

String → one label (“Mumbai”)
List → a queue ( ["A", "B", "C"])
Map → dictionary ( key → value pairs)
Object → a full form with fields ( name, age, role together)

Expressions and Functions in Terraform

In Terraform (from HashiCorp), expressions and functions are used to compute values dynamically instead of hardcoding them. 
They make your Infrastructure as Code flexible and powerful.

What are Expressions?

An expression is anything that produces a value.It can be:
A variable reference
A math operation
A condition
A function call

Types of Expressions

1.1 Basic Expressions - Refers to a variable value.
var.instance_type


1.2 Arithmetic Expressions - Used for calculations.
2 + 3
10 * 5


1.3 Conditional Expressions - If environment is prod → large instance, else small.
var.env == "prod" ? "large" : "small"

 
1.4 Interpolation Expressions - Creates dynamic strings.
"server-${var.env}"


Functions in Terraform

What are Functions?

A function is a built-in operation that transforms or computes values.

Syntax:

function_name(argument1, argument2)

Common Terraform Functions
2.1 length() - Returns number of elements.

length(["a", "b", "c"])

Output: 3

2.2 upper() / lower() - Converts text case.

upper("terraform")

Output: "TERRAFORM"

2.3 join() - Combines list into string.

join("-", ["dev", "app", "server"])

Output: "dev-app-server"

2.4 split() - Splits string into list.

split("-", "dev-app-server")

Output: ["dev", "app", "server"]

2.5 lookup() - Gets value from a map.

lookup({env = "dev", size = "t2.micro"}, "env")

Output: "dev"

2.6 merge() - Combines multiple maps.

merge({a = 1}, {b = 2})

Output: {a = 1, b = 2}

2.7 element() - Fetches item from list by index.

element(["a", "b", "c"], 1)

Output: "b"

