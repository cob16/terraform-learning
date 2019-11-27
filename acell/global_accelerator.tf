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
    endpoint_id = aws_lb.lb.arn
    weight = 100
  }

  health_check_path = ""
  health_check_interval_seconds = 10
  health_check_protocol = "TCP"
  health_check_port = 80
}

output "endpoint_group" {
  value = aws_globalaccelerator_accelerator.accelerator.ip_sets
}