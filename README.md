# AWS (free tier) account setup

This repo shares some instructions, good practices, tips and links to help you set up your AWS account. It is specifically aimed at developers that like to experimant with a private account to play with services on AWS. In the future I hopefully can share some IAC to automate some of the steps of this document.

## General AWS Free Tier information

https://aws.amazon.com/de/free/#legal

## Setup AWS Free Tier account

Create account: https://portal.aws.amazon.com/billing/signup#/start

### Follow best practices for root account

https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

> Enable AWS multi-factor authentication (MFA) on your AWS account root user account. For more information, see [Using Multi-Factor Authentication (MFA) in AWS.](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)

...

> use your account email address and password to sign in to the AWS Management Console and [create an IAM user for yourself](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) that has administrative permissions.

### Initial account configuration

-> Create separate (new) email account

-> Add account to smartphone to not miss any important mail

-> https://console.aws.amazon.com/iam/

-> MFA

-> "enable access to billing data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html)

-> Create Admin user: https://docs.aws.amazon.com/mediapackage/latest/ug/setting-up-create-iam-user.html

-> Signin with `Administrator` account

-> MFA (IAM->User Administrator->Security Credentials->Assigned MFA device

-> "Create IAM Policies That Grant Permissions to Billing Data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html)

 Create  BillingFullAccess and BillingViewAccess Policy

 Attach BillingFullAccess to Administrators Group

Budget (https://aws.amazon.com/getting-started/tutorials/control-your-costs-free-tier-budgets/)

-> Enable all billing alerts https://console.aws.amazon.com/billing/home?#/preferences


TODO: IAM password policy

TODO: Check how much of this can be replaced with https://registry.terraform.io/modules/terraform-aws-modules

### Account alias

https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html

or

https://docs.aws.amazon.com/cli/latest/reference/iam/create-account-alias.html

or

https://www.terraform.io/docs/providers/aws/r/iam_account_alias.html

### Create read only group

Create group `ReadOnly`.

Policies:
* `arn:aws:iam::aws:policy/ReadOnlyAccess`
* `arn:aws:iam::<your-account-id>:policy/BillingViewAccess`

### Create dev user

`dev-<username>` with console and access token access

Add to `ReadOnly` group.

Install [aws-vault](https://github.com/99designs/aws-vault/).

Use `aws-vault add <account-alias>` to add access key

Login as `dev-<username>`
Enable MFA

### Create role to assume

Create role `AdminRole` with policy `AdministratorAccess`.

Create policy `AssumeAdminRole`

    {
        "Version": "2012-10-17",
        "Statement": {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::<your-account-id>:role/AdminRole"
        }
    }

Create group `Sudo` with `AssumeAdminRole` policy
Attach `Sudo` group to `dev-<username>`

Setup aws-vault as described in `ubuntuInstall.txt`.

## Working with aws-vault

To work locally with AWS you can start an [EC2 Instance Metadata Service](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html).

    aws-vault exec --server dev@<account-alias>

## Serverless Framework

https://alligator.io/serverless/up-and-running-with-serverless/

    yarn global add serverless

https://github.com/baztian/serverless-hello-world

    $ aws-vault exec dev@<account-alias> -- ~/.yarn/bin/serverless deploy
    $ curl https://oqwycu31j0.execute-api.us-west-2.amazonaws.com/dev/hello
    $ aws-vault exec dev@<account-alias> -- ~/.yarn/bin/serverless remove

## Auto Shutdown and Start Amazon EC2 Instance

https://docs.aws.amazon.com/autoscaling/ec2/userguide/schedule_time.html

https://stackoverflow.com/questions/2413029/auto-shutdown-and-start-amazon-ec2-instance

https://aws.amazon.com/de/premiumsupport/knowledge-center/start-stop-lambda-cloudwatch/

https://stackoverflow.com/questions/19042025/amazon-ec2-free-tier-how-many-instances-can-i-run
