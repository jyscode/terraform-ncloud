resource "ncloud_login_key" "loginkey" { # 새로운 pem 인증서 생성
  key_name = "bastion-key"
}

resource "local_file" "login_key_file" { # 만들어진 인증 키 파일로 저장
    filename = "${ncloud_login_key.loginkey.key_name}.pem"
    content = ncloud_login_key.loginkey.private_key
}


resource "ncloud_subnet" "test" { # 외부와 통신을 위한 public subnet 생성
  vpc_no         = var.vpc_no
  subnet         = "10.10.2.0/24"
  zone           = "KR-1"
  network_acl_no = var.vpc_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
}

resource "ncloud_server" "server" { # bastion 서버 생성
  subnet_no                 = ncloud_subnet.test.subnet_no
  name                      = "my-tf-server"
  server_image_number       = "25624115"
  server_spec_code          = "c32-g2-s50"
  login_key_name            = ncloud_login_key.loginkey.key_name
}

resource "ncloud_public_ip" "public_ip" { # bastion 서버에 public ip 할당
  server_instance_no = ncloud_server.server.instance_no
}