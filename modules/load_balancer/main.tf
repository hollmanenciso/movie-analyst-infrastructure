resource "aws_lb" "this" {
  name               = format("%s-%s", var.name, "lb")
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnets
  security_groups    = var.security_groups

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "lb",
      )
    },
    var.tags,
  )
}
resource "aws_lb_target_group" "this" {
  name = format("%s-%s", var.name, "rt")

  vpc_id      = var.vpc_id
  target_type = var.target_type
  protocol    = var.target_protocol
  port        = var.target_port

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        "tg",
      )
    },
    var.tags,
  )
  depends_on = [aws_lb.this]
}
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
resource "aws_lb_target_group_attachment" "this" {
  count = length(var.target_ids)

  target_group_arn = aws_lb_target_group.this.arn
  target_id        = element(var.target_ids, count.index)
  port             = var.target_port
}
