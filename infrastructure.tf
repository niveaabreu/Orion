provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Projeto Techack"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-east-1a"  
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/28"
  availability_zone       = "us-east-1b"  
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/28"
  availability_zone       = "us-east-1b"  
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/28"
  availability_zone       = "us-east-1b"  
  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_security_group" "jump_sg" {
  name        = "jump-server-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name        = "database-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.prod_sg.id, aws_security_group.dev_sg.id]
  }
}

resource "aws_security_group" "prod_sg" {
  name        = "prod-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  ingress {
    from_port   = 10050
    to_port     = 10050
    protocol    = "tcp"
    security_groups = [aws_security_group.zabbix_sg.id]
  }
}

resource "aws_security_group" "dev_sg" {
  name        = "dev-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }
  ingress {
    from_port   = 10050
    to_port     = 10050
    protocol    = "tcp"
    security_groups = [aws_security_group.zabbix_sg.id]
  }
}

resource "aws_security_group" "zabbix_sg" {
  name        = "zabbix-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 10050
    to_port     = 10050
    protocol    = "tcp"
    security_groups = [aws_security_group.dev_sg.id, aws_security_group.prod_sg.id]
  }
}

resource "aws_security_group" "frontend_sg" {
  name        = "frontend-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "jump_server" {
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_group_names   = [aws_security_group.jump_sg.name]
  associate_public_ip_address = true
  key_name               = "bastion_host"

  user_data = <<-EOF
              #!/bin/bash
              # Install dependencies
              sudo apt-get update
              sudo apt-get install -y openssh-server libpam-google-authenticator

              sudo bash -c 'echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd'
              sudo bash -c 'echo "ChallengeResponseAuthentication yes" >> /etc/ssh/sshd_config'
              sudo systemctl restart ssh

              EOF
}


resource "aws_db_instance" "rds_instance" {
  identifier             = "banco-de-dados"
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "banco_de_dados"
  username               = "admin"
  password               = "admin1234"
  subnet_group_name      = "default"
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

resource "aws_instance" "prod_instance" {
  depends_on = [
    aws_db_instance.rds_instance,
    aws_instance.jump_server,
    aws_instance.zabbix_server
  ]
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_a.id
  security_group_names   = [aws_security_group.prod_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              # Install requirements
              sudo apt-get update
              sudo apt-get install -y git python3-pip

      
              git clone https://github.com/matheus-1618/Orion.git
              cd Orion

      
              pip3 install -r requirements.txt
              pip3 install numpy

		
	      echo "DB_PROVIDER=mysql" >> /home/ubuntu/Orion/.env
              echo "DB_DRIVER=mysqlconnector" >> /home/ubuntu/Orion/.env
              echo "DB_DATABASE_NAME=movies" >> /home/ubuntu/Orion/.env
              echo "DB_USER=admin" >> /home/ubuntu/Orion/.env
              echo "DB_PASSWORD=admin1234" >> /home/ubuntu/Orion/.env
              echo "DB_HOST=${aws_db_instance.rds_instance.endpoint}" >> /home/ubuntu/Orion/.env
              echo "DB_PORT=3306" >> /home/ubuntu/Orion/.env
              echo "DB_CONNECTION_STRING=\${DB_PROVIDER}+\${DB_DRIVER}://\${DB_USER}:\${DB_PASSWORD}@\${DB_HOST}:\${DB_PORT}/\${DB_DATABASE_NAME}" >> /home/ubuntu/Orion/.env
              python3 create.py

              sudo apt-get install -y zabbix-agent

              # Configure Zabbix agent
	      echo "Server=${aws_instance.zabbix_server.private_ip}" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	      echo "ServerActive=${aws_instance.zabbix_server.private_ip}:10050" | sudo tee -a /etc/zabbix/zabbix_agentd.conf


              sudo apt-get install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              sudo bash -c 'echo "server { listen 80; server_name localhost; location / { proxy_pass http://127.0.0.1:8000; } }" > /etc/nginx/sites-available/default'
              sudo systemctl restart nginx

              cd Orion
              uvicorn main:app --host 0.0.0.0 --port 8000 &
              EOF
}

resource "aws_instance" "dev_instance" {
  depends_on = [
    aws_db_instance.rds_instance,
    aws_instance.jump_server,
    aws_instance.zabbix_server
  ]
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet_b.id
  security_group_names   = [aws_security_group.dev_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              # Install requirements
              sudo apt-get update
              sudo apt-get install -y git python3-pip

       
              git clone -b dev https://github.com/matheus-1618/Orion.git
              cd Orion

              pip3 install -r requirements.txt
              pip3 install numpy
              
	      echo "DB_PROVIDER=mysql" >> /home/ubuntu/Orion/.env
              echo "DB_DRIVER=mysqlconnector" >> /home/ubuntu/Orion/.env
              echo "DB_DATABASE_NAME=moviesDev" >> /home/ubuntu/Orion/.env
              echo "DB_USER=admin" >> /home/ubuntu/Orion/.env
              echo "DB_PASSWORD=admin1234" >> /home/ubuntu/Orion/.env
              echo "DB_HOST=${aws_db_instance.rds_instance.endpoint}" >> /home/ubuntu/Orion/.env
              echo "DB_PORT=3306" >> /home/ubuntu/Orion/.env
              echo "DB_CONNECTION_STRING=\${DB_PROVIDER}+\${DB_DRIVER}://\${DB_USER}:\${DB_PASSWORD}@\${DB_HOST}:\${DB_PORT}/\${DB_DATABASE_NAME}" >> /home/ubuntu/Orion/.env

              python3 create.py

              sudo apt-get install -y zabbix-agent

	      echo "Server=${aws_instance.zabbix_server.private_ip}" | sudo tee -a /etc/zabbix/zabbix_agentd.conf
	      echo "ServerActive=${aws_instance.zabbix_server.private_ip}:10050" | sudo tee -a /etc/zabbix/zabbix_agentd.conf

              sudo apt-get install -y nginx
              sudo systemctl enable nginx
              sudo systemctl start nginx
              sudo bash -c 'echo "server { listen 80; server_name localhost; location / { proxy_pass http://127.0.0.1:8000; } }" > /etc/nginx/sites-available/default'
              sudo systemctl restart nginx

              cd Orion
              uvicorn main:app --host 0.0.0.0 --port 8000 &
              EOF
}

resource "aws_instance" "zabbix_server" {
  depends_on = [
    aws_instance.jump_server,
  ]
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_group_names   = [aws_security_group.zabbix_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              # Install requirements
              sudo apt-get update
              sudo apt-get install -y mysql-server nginx

              sudo mysql -e "CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;"
              sudo mysql -e "CREATE USER 'zabbix'@'%' IDENTIFIED BY 'your_zabbix_password';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';"
              sudo mysql -e "FLUSH PRIVILEGES;"


              sudo apt-get install -y zabbix-server-mysql zabbix-frontend-php
              sudo apt-get install -y zabbix-agent

              sudo bash -c 'echo "DBHost=localhost" >> /etc/zabbix/zabbix_server.conf'
              sudo bash -c 'echo "DBName=zabbix" >> /etc/zabbix/zabbix_server.conf'
              sudo bash -c 'echo "DBUser=zabbix" >> /etc/zabbix/zabbix_server.conf'
              sudo bash -c 'echo "DBPassword=your_zabbix_password" >> /etc/zabbix/zabbix_server.conf'

              sudo bash -c 'echo "date.timezone = America/New_York" >> /etc/php/7.4/apache2/php.ini'

              sudo bash -c 'echo "server { listen 80; server_name localhost; root /usr/share/zabbix; index index.php index.html index.htm; location ~ \\.php$ { include snippets/fastcgi-php.conf; fastcgi_pass unix:/var/run/php/php7.4-fpm.sock; fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; include fastcgi_params; } }" > /etc/nginx/sites-available/default'
              sudo systemctl restart nginx

              sudo systemctl start zabbix-server
              sudo systemctl enable zabbix-server

              sudo systemctl start zabbix-agent
              sudo systemctl enable zabbix-agent
              EOF
}


resource "aws_instance" "frontend_instance" {
  depends_on = [
    aws_db_instance.prod_instance,
    aws_instance.dev_instance
  ]
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_group_names   = [aws_security_group.frontend_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y nginx

              sudo bash -c 'echo "server { listen 80; server_name localhost; location / { proxy_pass http://prod_server_ip:8080; } }" > /etc/nginx/sites-available/default'
              sudo bash -c 'echo "server { listen 8081; server_name localhost; location / { proxy_pass http://dev_server_ip:80; } }" > /etc/nginx/sites-available/dev'
              sudo systemctl restart nginx

              EOF
}

resource "aws_instance" "jenkins_instance" {
  depends_on = [
    aws_db_instance.prod_instance,
    aws_instance.dev_instance
  ]
  ami                    = "ami-0fc5d935ebf8bc3bc"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet.id
  security_group_names   = [aws_security_group.jenkins_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y openjdk-8-jdk

              wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
              sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
              sudo apt-get update
              sudo apt-get install -y jenkins

              sudo systemctl start jenkins
              sudo systemctl enable jenkins

              EOF
}



