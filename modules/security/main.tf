locals {
  sg_id = aws_security_group.this.id
}

resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
  )
}

resource "aws_security_group_rule" "ingress_with_cidr" {
  count = length(var.from_port_cidr_block)

  security_group_id = local.sg_id
  type              = "ingress"

  from_port   = element(var.from_port_cidr_block, count.index)
  to_port     = element(var.to_port_cidr_block, count.index)
  protocol    = element(var.protocol_cidr_block, count.index)
  cidr_blocks = [element(var.cidr_block, count.index)]
}

resource "aws_security_group_rule" "ingress_with_sg" {
  count = length(var.from_port_sg_id)

  security_group_id = local.sg_id
  type              = "ingress"

  from_port                = element(var.from_port_sg_id, count.index)
  to_port                  = element(var.to_port_sg_id, count.index)
  protocol                 = element(var.protocol_sg_id, count.index)
  source_security_group_id = element(var.source_security_group_id, count.index)
}

resource "aws_security_group_rule" "allow_all" {
  count = var.allow_all ? 1 : 0

  security_group_id = local.sg_id
  type              = "egress"

  to_port     = 0
  protocol    = "-1"
  from_port   = 0
  cidr_blocks = ["0.0.0.0/0"]
}
