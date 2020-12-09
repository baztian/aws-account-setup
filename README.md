# AWS (free tier) account setup

This repo shares some instructions, good practices, tips and links to help you set up your AWS account. It is specifically aimed at developers that like to experimant with a private account to play with services on AWS. In the future I hopefully can share some IAC to automate some of the steps of this document.

## General AWS Free Tier information

https://aws.amazon.com/de/free/#legal

## Setup AWS Free Tier account

Create account: https://portal.aws.amazon.com/billing/signup#/start

### Follow best practices for root account

https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

TODO: Automate using https://github.com/terraform-aws-modules/terraform-aws-iam#iam-best-practices

> Enable AWS multi-factor authentication (MFA) on your AWS account root user account. For more information, see [Using Multi-Factor Authentication (MFA) in AWS.](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)

...

> use your account email address and password to sign in to the AWS Management Console and [create an IAM user for yourself](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) that has administrative permissions.

### Initial account configuration

-> Create separate (new) email account

-> Add account to smartphone to not miss any important mail

-> https://console.aws.amazon.com/iam/

-> MFA

-> Payment Currency Preference (Account settings) to EUR

-> "enable access to billing data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html)

-> Create Admin user: https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html

-> Signin with `Administrator` account

-> MFA (IAM->User Administrator->Security Credentials->Assigned MFA device

-> "Create IAM Policies That Grant Permissions to Billing Data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html) # I think it's now replaced with terraform code

 Create  BillingFullAccess and BillingViewAccess Policy # I think it's now replaced with terraform code

 Attach BillingFullAccess to Administrators Group # I think it's now replaced with terraform code

Budget (https://aws.amazon.com/getting-started/tutorials/control-your-costs-free-tier-budgets/)

-> Enable billing alerts https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/monitor_estimated_charges_with_cloudwatch.html#turning_on_billing_metrics

TODO: IAM password policy

### Account alias

Set up in `global/account/account.tf`

See also

https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html

or

https://docs.aws.amazon.com/cli/latest/reference/iam/create-account-alias.html

or

https://www.terraform.io/docs/providers/aws/r/iam_account_alias.html

### User setup

Set up in `global/account/user.tf`

Setup aws-vault as described in `ubuntuInstall.txt`.

## Working with aws-vault

To work locally with AWS you can start an [EC2 Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

    aws-vault exec --server dev@<account-alias>

## terraform

https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## Auto Shutdown and Start Amazon EC2 Instance

https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html

https://stackoverflow.com/questions/2413029/auto-shutdown-and-start-amazon-ec2-instance

https://aws.amazon.com/de/premiumsupport/knowledge-center/start-stop-lambda-cloudwatch/

https://stackoverflow.com/questions/19042025/amazon-ec2-free-tier-how-many-instances-can-i-run
