output "elb_dns_name" {
  value = aws_elb.app_lb.dns_name
}