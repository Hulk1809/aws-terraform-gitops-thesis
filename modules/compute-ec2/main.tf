data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_iam_role" "ec2_ecr_role" {
  name = "${var.environment}-ec2-ecr-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_ecr_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-ecr-profile"
  role = aws_iam_role.ec2_ecr_role.name
}

resource "aws_instance" "app_server" {
  #checkov:skip=CKV_AWS_88:Can Public IP vi khong dung NAT Gateway
  #checkov:skip=CKV_AWS_126:Detailed monitoring tinh phi CloudWatch
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  ebs_optimized               = true
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true
  monitoring                  = false
  user_data_replace_on_change = true
  depends_on                  = [aws_iam_role_policy_attachment.ecr_readonly]

  credit_specification {
    cpu_credits = "standard"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -euo pipefail

    ECR_URL="${var.ecr_repository_url}"
    REGION="${var.aws_region}"
    REGISTRY="$${ECR_URL%%/*}"
    IMAGE="$ECR_URL:${var.image_tag}"

    dnf install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user

    for i in $(seq 1 10); do
      aws ecr get-login-password --region "$REGION" \
        | docker login --username AWS --password-stdin "$REGISTRY" && break
      sleep 10
    done

    docker pull "$IMAGE"
    TOKEN=$(curl --fail --silent --show-error --retry 5 -X PUT \
      -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' \
      http://169.254.169.254/latest/api/token)
    metadata() {
      curl --fail --silent --show-error --retry 5 \
        -H "X-aws-ec2-metadata-token: $TOKEN" \
        "http://169.254.169.254/latest/meta-data/$1"
    }
    mkdir -p /opt/thesis
    BOOT_TIME=$(awk '/^btime / {print $2}' /proc/stat)
    printf '{"instance_id":"%s","region":"%s","availability_zone":"%s","boot_time":%s}\n' \
      "$(metadata instance-id)" "$(metadata placement/region)" \
      "$(metadata placement/availability-zone)" "$BOOT_TIME" > /opt/thesis/runtime.json
    chmod 644 /opt/thesis/runtime.json
    unset TOKEN
    docker run -d --restart always -p 80:80 --name thesis-web-app \
      --security-opt no-new-privileges:true \
      -v /opt/thesis/runtime.json:/usr/share/nginx/html/runtime.json:ro "$IMAGE"
  EOF

  tags = { Name = "${var.environment}-Thesis-FreeTier-EC2" }
}
