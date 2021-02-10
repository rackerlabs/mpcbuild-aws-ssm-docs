terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = ">= 2.70.0"
  }
}

resource "aws_ssm_document" "mount_document" {
  name          = "Rack-MountAdditionalVolumes"
  document_type = "Command"
  target_type   = "/AWS::EC2::Instance"
  content       = file("${path.module}/files/ssm_document_mount_volumes.json")
}

resource "aws_ssm_document" "golden_ami_doc" {
  name          = "Rack-GoldenImageMPCBuild"
  document_type = "Automation"
  content       = file("${path.module}/files/ssm_document_automate_golden_ami.json")

  depends_on = [aws_ssm_document.mount_document]
}
