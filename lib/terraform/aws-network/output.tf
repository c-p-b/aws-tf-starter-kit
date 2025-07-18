output "vpc_id" {
  value       = aws_vpc.this.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = [for subnet in aws_subnet.public : subnet.id]
  description = "IDs of the public subnets, if any exist"
}

output "private_subnet_ids" {
  value       = [for subnet in aws_subnet.private : subnet.id]
  description = "IDs of the private subnets, if any exist"
}

output "all_subnet_ids" {
  value       = concat([for subnet in aws_subnet.public : subnet.id], [for subnet in aws_subnet.private : subnet.id])
  description = "IDs of all subnets"
}

output "main_route_table_id" {
  value       = aws_route_table.main_rtb.id
  description = "The ID of the main route table"
}

output "private_subnet_route_table_ids" {
  value       = [for rt in aws_route_table.private_subnet_rtb : rt.id]
  description = "The IDs of the private subnet route tables"
}

output "public_subnet_route_table_ids" {
  value       = [for v in aws_route_table.public_subnet_rtb : v.id]
  description = "The IDs of the public subnet route tables"
}

output "all_subnet_route_table_ids" {
  value       = concat([for v in aws_route_table.public_subnet_rtb : v.id], [for v in aws_route_table.private_subnet_rtb : v.id])
  description = "IDs of all subnet route tables"
}
