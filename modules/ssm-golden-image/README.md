# Automated Golden Image

This solution is based on two SSM documents:

**Rack-MountAdditionalVolumes:** SSM document type Command that can be used to mount additional EBS volumes without manual OS interaction, providing either the mount points (Linux) or device units and their descriptions (Windows). It can also mount EFS filesystems (only for Linux instances) if the EFS domain name is provided.

**Rack-GoldenImageMPCBuild:** SSM document type Automation that is a modified version of the usual Rackspace automation. Can be invoked using the IAM automation role normally created during TF base deployment. It works for both Linux and Windows. The automation consists of the following steps:
* Driver update and Sysprep (only for Windows instances)
* Mount additional EBS volumes with the document Rack-MountAdditionalVolumes
* OS updates with patch updates
* Generate AMI
* (Optional) Encrypt image using the CopyAMI API call. NOTE: If a CMK is selected for encryption, make sure the automation role have the additional inline policy mentioned below

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "kms:GenerateDataKeyWithoutPlaintext",
                "kms:DescribeKey",
                "kms:CreateGrant"
            ],
            "Resource": "*"
        }
    ]
}
```

These documents are intented to be used after the Build engineer has deployed the first version of the EC2 instance using the official TF module.

**IMPORTANT NOTE:** Don't use the automation directly on instances that are part of an ASG. The process will stop the instance at least one time, so to use it on instances launched from ASG, first deregister them from the group and then run the process; this step may need to modify min and desired values for the ASG.

## TF module execution

The execution below will create both documents

```
module "ssm_golden_ami" {
   source = "git@github.com:rackerlabs/mpcbuild-aws-ssm-docs//modules/ssm-golden-image"
}
```

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.70.0 |

## Inputs

No input.

## Outputs

No output.

## Execution examples (from the console)
Below are the snapshot to exemplify how to execute the automations based on the use case:

* Mounting volumes on Linux instances
![LinuxMount](./images/ssm_doc_linux.JPG?raw=true)

* Mounting volumes on Windows instances
![WinMount](./images/ssm_doc_windows.JPG?raw=true)

* Mounting EFS filesystem
![EFSMount](./images/ssm_doc_efs.JPG?raw=true)

* Full Golden AMI automation for Linux instances
![LinuxImage](./images/ssm_golden_ami_linux.JPG?raw=true)

* Full Golden AMI automation for Windows instances
![WinImage](./images/ssm_golden_ami_windows.JPG?raw=true)

## Execution examples (from CLI)
* For the execution of document Rack-MountAdditionalVolumes, use the following command (make sure you change the proper instanceID value):
```
aws ssm send-command --document-name "Rack-MountAdditionalVolumes" --targets "Key=instanceids,Values=i-xxxxxxxxxxxxxxxxx" --cli-input-json file://ssm_param.json
```

For the content of the file ssm_param.json, change it accordingly the OS use case.

Linux example:
```
{
	"Parameters": {
		"EBSPaths": [
			"/data"
		],
		"EFSDomainName": [
			"fs-0deee814.efs.us-west-1.amazonaws.com"
		],
		"EFSMountPoint": [
			"/share"
		]
	}
}
```

Windows example:
```
{
	"Parameters": {
		"EBSUnits": [
			"\"D\", \"F\""
		],
		"EBSDescriptions": [
			"\"Data\", \"Backup\""
		]
	}
}
```

* For the execution of automation Rack-GoldenImageMPCBuild, execute the following command:
```
aws ssm start-automation-execution --document-name "Rack-GoldenImageMPCBuild" --cli-input-json file://ssm_param.json
```

For the content of the file ssm_param.json, change it accordingly the OS use case.

Linux example:
```
{
	"Parameters": {
		"AutomationAssumeRole": [
			"arn:aws:iam::930160882122:role/AutomationServiceRole-20210105163657887300000001"
		],
		"InstanceId": [
			"i-05b1e8104b5ace350"
		],
		"EBSPaths": [
			"/data /backup"
		],
		"EFSDomainName": [
			"fs-0deee814.efs.us-west-1.amazonaws.com"
		],
		"EFSMountPoint": [
			"/share"
		],
		"GoldenImageName": [
			"AMI-Linux-Test"
		],
		"EncryptImage": [
			"True"
		]
	}
}
```

Windows example:
```
{
	"Parameters": {
		"AutomationAssumeRole": [
			"arn:aws:iam::930160882122:role/AutomationServiceRole-20210105163657887300000001"
		],
		"InstanceId": [
			"i-0510f689ee30ab975"
		],
		"EBSUnits": [
			"\"D\", \"F\", \"H\""
		],
		"EBSDescriptions": [
			"\"Data\", \"Backup\", \"Test\""
		],
		"GoldenImageName": [
			"AMI-Windows-Test"
		]
	}
}
```