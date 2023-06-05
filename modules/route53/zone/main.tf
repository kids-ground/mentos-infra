// 생성 후 - NS 레코드 기존 네임서버에 넣기
resource "aws_route53_zone" "zone" {
  name = var.name
  comment = var.name
}