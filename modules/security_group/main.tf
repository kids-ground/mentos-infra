resource "aws_security_group" "sg" {
  vpc_id = var.vpc_id
  name = var.name
}

resource "aws_security_group_rule" "allow_inboud" {
  type = "ingress"
  for_each = var.inbound_rule
  security_group_id = aws_security_group.sg.id

  from_port = each.value["port"]
  to_port = each.value["port"]
  protocol = each.value["protocol"]
  cidr_blocks = each.value["cidr_blocks"]
}

resource "aws_security_group_rule" "outbound" {
  type = "egress"
  for_each = var.outbound_rule
  security_group_id = aws_security_group.sg.id

  from_port = each.value["port"]
  to_port = each.value["port"]
  protocol = each.value["protocol"]
  cidr_blocks = each.value["cidr_blocks"]
}
