locals {
  ec2_id = aws_instance.this.*.id
}

resource "aws_instance" "this" {
  count = length(var.subnet_ids)

  ami = var.ami

  instance_type = var.instance_type

  subnet_id                   = element(var.subnet_ids, count.index)
  associate_public_ip_address = var.associate_public_ip_address
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64

  vpc_security_group_ids = var.vpc_security_group_ids

  key_name = var.key_name
  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        count.index,
      )
    },
    var.tags,
  )
}
