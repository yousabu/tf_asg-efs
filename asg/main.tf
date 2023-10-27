resource "aws_launch_configuration" "fw-lt" {
  name_prefix   = "${var.env_prefix}-fw-lt"
  image_id      = var.ami_image
  associate_public_ip_address = true
  instance_type = var.instance_type
  security_groups = var.security_groups
  key_name = var.key_name  

  user_data = <<-EOF
              #!/bin/bash
              EFS_FILE_SYSTEM_ID="${var.efs_dns_name}"
              AWS_REGION="us-east-1"
              MOUNT_POINT="/mnt/efs/"
              sudo apt-get update -y
              sudo apt-get install -y nfs-common

              test_dns_resolution() {
                  if nslookup "${var.efs_dns_name}" >/dev/null 2>&1; then
                      return 0  # Success
                  else
                      return 1  # Failure
                  fi
              }

              while ! test_dns_resolution; do
                  sleep 20
              done

              sudo apt install nginx -y
              sudo mkdir -p $MOUNT_POINT
              sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 $EFS_FILE_SYSTEM_ID:/ $MOUNT_POINT
              sudo echo $EFS_FILE_SYSTEM_ID:/ $MOUNT_POINT nfs defaults 0 0" >> /etc/fstab
              EOF
  
}



resource "aws_autoscaling_group" "fawry" {
  name                      = var.asg_name
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = var.desired_capacity
  force_delete              = true
  vpc_zone_identifier = var.sunbets_nums
  
  launch_configuration      = aws_launch_configuration.fw-lt.name
#  depends_on = [module.vpc, aws_launch_configuration.fw-lt, module.vpc, aws_efs_file_system.efs ]
}