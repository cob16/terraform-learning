data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "key-pair"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.ssh-key.key_name

  subnet_id              = aws_subnet.public-1.id
  vpc_security_group_ids = [aws_security_group.public.id]
  ipv6_address_count     = 1

  user_data = <<-EOF
    #! /bin/bash
    set -euo pipefail
    set +o xtrace
    echo "running userdata script"

    sudo apt-get update
    sudo apt-get upgrade -y

    sudo apt-get install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx

    echo "1.2.3" > sudo tee /var/www/html/version.txt

    echo "done"
  EOF

  tags = {
    Name = "test-instance"
  }
}

output "ip" {
  value = aws_instance.web.public_ip
}

output "ipv6" {
  value = aws_instance.web.ipv6_addresses
}

output "dns" {
  value = aws_instance.web.public_dns
}
