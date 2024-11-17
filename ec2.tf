resource "aws_instance" "terraform" {
  ami           = "ami-0f3a440bbcff3d043" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF
  user_data_replace_on_change = true
  

  tags  =  { 
    Name  =  "terraform"  
  } 
}

resource  "aws_security_group" "instance"  {
  name  =  "terraform-instance" 
  
  ingress  { 
    from_port    =  var.server_port 
    to_port      =  var.server_port 
    protocol     =  "tcp"
    cidr_blocks  =  [ "0.0.0.0/0" ] 
  }
}

output "public_ip" {
 value = aws_instance.terraform.public_ip
 description = "The public IP address of the web server"
}