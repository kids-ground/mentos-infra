resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project_name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "db" {
  identifier = "${var.project_name}-rds"
  vpc_security_group_ids = [ var.db_sg_id ]
  availability_zone = var.db_az_name
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  # 기본 데이터 인코딩 - utf8mb4
  engine = "mysql"
  engine_version = "8.0.33"
  instance_class = "db.t4g.micro"
  
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password

  max_allocated_storage = 1000
  allocated_storage = 20
  backup_retention_period = 5 # 백업본 저장기간
  ca_cert_identifier = "rds-ca-2019"
  storage_encrypted = true

  copy_tags_to_snapshot = true
  skip_final_snapshot = true
}