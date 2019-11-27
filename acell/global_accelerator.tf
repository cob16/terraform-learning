resource "aws_instance" "instance" {
  count = 2

  ami           = "ami-05f37c3995fffb4fd"
  instance_type = "t2.micro"

  user_data = <<EOF
#!/bin/bash
sudo amazon-linux-extras install -y nginx1
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
EOF

}

resource "aws_eip" "internal_ip_1" {}
resource "aws_eip" "internal_ip_2" {}

resource "aws_eip_association" "internal_ip_1" {
  instance_id   = aws_instance.instance.1.id
  allocation_id = aws_eip.internal_ip_1.id
}

resource "aws_eip_association" "internal_ip_2" {
  instance_id   = aws_instance.instance.0.id
  allocation_id = aws_eip.internal_ip_2.id
}

resource "aws_globalaccelerator_accelerator" "accelerator" {
  name = module.label.id
}

resource "aws_globalaccelerator_listener" "accelerator_listener" {
  accelerator_arn = aws_globalaccelerator_accelerator.accelerator.id
  protocol = "TCP"
  port_range {
    from_port = 80
    to_port = 80
  }
}


resource "aws_globalaccelerator_endpoint_group" "endpoint_1" {
  listener_arn = aws_globalaccelerator_listener.accelerator_listener.id

  endpoint_configuration {
    endpoint_id = aws_eip.internal_ip_1.id
    weight = 50
  }

  endpoint_configuration {
    endpoint_id = aws_eip.internal_ip_2.id
    weight = 50
  }

  health_check_path = "/"
  health_check_interval_seconds = 10
  health_check_protocol = "TCP"
  health_check_port = 80
}

output "endpoint_group" {
  value = aws_globalaccelerator_accelerator.accelerator.ip_sets
}