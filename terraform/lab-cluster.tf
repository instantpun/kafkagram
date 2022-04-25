resource "aws_vpc" "vpc" {
  cidr_block = "192.168.100.0/22"
}

data "aws_availability_zones" "azs" {
  state = "available"
}

resource "aws_subnet" "subnet_az1" {
  availability_zone = data.aws_availability_zones.azs.names[0]
  cidr_block        = "192.168.100.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az2" {
  availability_zone = data.aws_availability_zones.azs.names[1]
  cidr_block        = "192.168.101.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_az3" {
  availability_zone = data.aws_availability_zones.azs.names[2]
  cidr_block        = "192.168.102.0/24"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_security_group" "sg" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_kms_key" "msk_key" {
  description         = "MSK Home lab key"
  key_usage           = "ENCRYPT_DECRYPT"
  is_enabled          = true
  enable_key_rotation = true
}

resource "aws_cloudwatch_log_group" "msk_broker_logs" {
  name = "cw-group__msk_broker_logs"
}

resource "aws_s3_bucket" "logs_bucket" {
  bucket = "msk_broker_logs"
}

resource "aws_s3_bucket_acl" "logs_bucket_acl" {
  bucket = aws_s3_bucket.logs_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "firehose_allow_all" {
  name = "firehose_allow_all"

  assume_role_policy = <<EOF
{
"Version": "2022-04-25",
"Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "firehose.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
  }
  ]
}
EOF
}

resource "aws_kinesis_firehose_delivery_stream" "msk_broker_logs" {
  name        = "firehose__msk_broker_logs"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose_allow_all.arn
    bucket_arn = aws_s3_bucket.logs_bucket.arn
  }

  tags = {
    LogDeliveryEnabled = "placeholder"
  }

  lifecycle {
    ignore_changes = [
      tags["LogDeliveryEnabled"],
    ]
  }
}

resource "aws_msk_cluster" "home-lab" {
  cluster_name           = "home-lab"
  kafka_version          = "2.6.2"
  number_of_broker_nodes = 3

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    ebs_volume_size = 100
    client_subnets = [
      aws_subnet.subnet_az1.id,
      aws_subnet.subnet_az2.id,
      aws_subnet.subnet_az3.id,
    ]
    security_groups = [aws_security_group.sg.id]
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk_key.arn
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_broker_logs.name
      }
      firehose {
        enabled         = true
        delivery_stream = aws_kinesis_firehose_delivery_stream.msk_broker_logs.name
      }
      s3 {
        enabled = true
        bucket  = aws_s3_bucket.logs_bucket.id
        prefix  = "logs/msk-"
      }
    }
  }

  tags = {
    foo = "bar"
  }
}

output "zookeeper_connect_string" {
  value = aws_msk_cluster.home-lab.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.home-lab.bootstrap_brokers_tls
}