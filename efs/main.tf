### EFS ###
resource "aws_efs_file_system" "efs" {
  creation_token = "my-efs"
  performance_mode = "generalPurpose"
  throughput_mode = "bursting"
  encrypted = true
  tags = {
    Name = "my-efs"
  }

    lifecycle {
    ignore_changes = all
  }
}

resource "aws_efs_mount_target" "efs_mount_target" {
  count =  length(var.sunbets_nums)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = var.sunbets_nums[count.index]
  security_groups = var.security_groups
  depends_on = [aws_efs_file_system.efs]
    lifecycle {
    ignore_changes = all
  }
}