
data "ncloud_subnet" "selected" { # 서브넷 받아오기, k8s node 있는 private subnet
    id = var.subnet_no
}

resource "ncloud_mysql" "mysql" { # 관리형 MySQL 생성 
  subnet_no = data.ncloud_subnet.selected.id
  service_name = "kjy-mysql"
  server_name_prefix = "tef"
  user_name = "jiyong"
  user_password = "password123!"
  host_ip = "%"
  database_name = "kjy-db"
}

