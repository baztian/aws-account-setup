## General AWS Free Tier information

https://aws.amazon.com/de/free/#legal

## Auto Shutdown and Start Amazon EC2 Instance

https://stackoverflow.com/questions/2413029/auto-shutdown-and-start-amazon-ec2-instance

https://aws.amazon.com/de/premiumsupport/knowledge-center/start-stop-lambda-cloudwatch/

https://stackoverflow.com/questions/19042025/amazon-ec2-free-tier-how-many-instances-can-i-run

## Setup AWS Free Tier account

Create account: https://portal.aws.amazon.com/billing/signup#/start

### Follow best practices for root account

https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

> Enable AWS multi-factor authentication (MFA) on your AWS account root user account. For more information, see [Using Multi-Factor Authentication (MFA) in AWS.](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)

...

> use your account email address and password to sign in to the AWS Management Console and [create an IAM user for yourself](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html) that has administrative permissions.

### Initial account configuration

-> Create new Gmail Account

-> Add Account to Smartphone

-> https://console.aws.amazon.com/iam/

-> MFA

-> "enable access to billing data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html)

-> Create Admin user: https://docs.aws.amazon.com/mediapackage/latest/ug/setting-up-create-iam-user.html

-> Signin with Administrator account

-> MFA (IAM->User Administrator->Security Credentials->Assigned MFA device

-> "Create IAM Policies That Grant Permissions to Billing Data" (https://docs.aws.amazon.com/IAM/latest/UserGuide/tutorial_billing.html)

 Create  BillingFullAccess and BillingViewAccess Policy

 Attach BillingFullAccess to Administrators Group

Budget (https://aws.amazon.com/getting-started/tutorials/control-your-costs-free-tier-budgets/)

-> Enable all billing alerts https://console.aws.amazon.com/billing/home?#/preferences


TODO: IAM password policy

### Account alias

https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html

https://docs.aws.amazon.com/cli/latest/reference/iam/create-account-alias.html

https://www.terraform.io/docs/providers/aws/r/iam_account_alias.html

### Create read only group

Create group "ReadOnly".
Policies:
* arn:aws:iam::aws:policy/ReadOnlyAccess
* arn:aws:iam::961704225731:policy/BillingViewAccess

### Create dev user

dev-<username> with console and access token access

Add to ReadOnly group.

Use aws-vault add ... to add access key

Login as dev-<username>
Enable MFA

### Create role to assume

Create role "AdminRole" with policy "AdministratorAccess".

Create policy "AssumeAdminRole"

{
    "Version": "2012-10-17",
    "Statement": {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Resource": "arn:aws:iam::961704225731:role/AdminRole"
    }
}

Create group "Sudo" with "AssumeAdminRole" policy
Attach "Sudo" group to dev-<username>

Setup aws-vault as described in `ubuntuInstall.txt`.

## Serverless Framework

https://alligator.io/serverless/up-and-running-with-serverless/

    yarn global add serverless

https://github.com/baztian/serverless-hello-world

    $ aws-vault exec dev@babowe2019 -- ~/.yarn/bin/serverless deploy
    $ curl https://oqwycu31j0.execute-api.us-west-2.amazonaws.com/dev/hello
    $ aws-vault exec dev@babowe2019 -- ~/.yarn/bin/serverless remove