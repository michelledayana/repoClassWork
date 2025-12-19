#################################
# PROVIDER
#################################
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project = "Distributed-Classwork"
      Owner   = "Heredia and Vasco"
    }
  }
}

#################################
# DATA
#################################
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#################################
# RANDOM ID (para TG names)
#################################
resource "random_id" "tg_id" {
  byte_length = 4
}

#################################
# SECURITY GROUPS
#################################
resource "aws_security_group" "app_sg" {
  name   = "classwork-app-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "classwork-db-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#################################
# LOAD BALANCER
#################################
resource "aws_lb" "alb" {
  name               = "classwork-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = data.aws_subnets.default.ids
}

#################################
# TARGET GROUPS (names fixed)
#################################
resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg-${random_id.tg_id.hex}"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name        = "backend-tg-${random_id.tg_id.hex}"
  port        = 3000
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#################################
# LISTENER
#################################
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

#################################
# LISTENER RULE (backend route)
#################################
resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

#################################
# DATABASE INSTANCE
#################################
resource "aws_instance" "database" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[2]
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

docker run -d --name db \
  -e POSTGRES_DB=appdb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  dayanaheredia/class-work-db:latest
EOF

  tags = {
    Name = "db-instance"
  }
}

#################################
# BACKEND INSTANCE
#################################
resource "aws_instance" "backend" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[1]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  depends_on = [aws_instance.database]

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

docker run -d --name backend \
  -e DB_HOST=${aws_instance.database.private_ip} \
  -e DB_PORT=5432 \
  -e DB_NAME=appdb \
  -e DB_USER=postgres \
  -e DB_PASSWORD=postgres \
  -p 3000:3000 \
  dayanaheredia/class-work-backend:latest
EOF

  tags = {
    Name = "backend-instance"
  }
}

#################################
# FRONTEND INSTANCE
#################################
resource "aws_instance" "frontend" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<EOF
#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker

docker run -d --name frontend \
  -e BACKEND_URL=http://${aws_lb.alb.dns_name}/api \
  -p 80:80 \
  dayanaheredia/class-work-frontend:latest
EOF

  tags = {
    Name = "frontend-instance"
  }
}

#################################
# ATTACH INSTANCES TO TARGET GROUPS
#################################
resource "aws_lb_target_group_attachment" "frontend_attach" {
  target_group_arn = aws_lb_target_group.frontend_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "backend_attach" {
  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend.id
  port             = 3000
}
