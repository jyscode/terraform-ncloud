resource "ncloud_vpc" "vpc" { # 새로운 vpc 환경 생성
  name            = "k8s-vpc"
  ipv4_cidr_block = "10.10.0.0/16"
}

output "vpc_no" { # vpc 이름 변수로 출력
  value = ncloud_vpc.vpc.vpc_no
}

output "vpc_acl_no" { # vpc생성 시 생성되는 acl 변수로 출력
  value = ncloud_vpc.vpc.default_network_acl_no
}

resource "ncloud_subnet" "subnet" { # k8s node가 위치할 private subnet 생성 
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.10.1.0/24"
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "subnet-01"
  usage_type     = "GEN" # 타입 - 일반
}

output "subnet_no" { # 일반 private 서브넷 id 출력
  value = ncloud_subnet.subnet.id
}

resource "ncloud_subnet" "subnet_lb" { # lb 용 private subnet 생성
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.10.100.0/24"
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "subnet-lb"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "subnet_lb_pub" { # lb용 public subnet 생성
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.10.101.0/24"
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PUBLIC"
  name           = "subnet-lb-pub"
  usage_type     = "LOADB"
}

resource "ncloud_subnet" "subnet-nat" { # NAT용 Subnet 생성 
  vpc_no         = ncloud_vpc.vpc.id
  subnet         = "10.10.10.0/24"
  zone           = "KR-1"
  network_acl_no = ncloud_vpc.vpc.default_network_acl_no
  subnet_type    = "PUBLIC" // PUBLIC(Public) | PRIVATE(Private)
  usage_type     = "NATGW"
}

resource "ncloud_nat_gateway" "nat_gateway" { # NATGW 생성
  vpc_no      = ncloud_vpc.vpc.id
  subnet_no   = ncloud_subnet.subnet-nat.id
  zone        = "KR-1"
  // below fields are optional
  name        = "nat-gw"
  description = "description"
}

data "ncloud_route_table" "selected" { # private route table 선택
  vpc_no                = ncloud_vpc.vpc.id
  supported_subnet_type = "PRIVATE"
  filter {
    name = "is_default"
    values = ["true"]
  }
}

resource "ncloud_route" "route-nat" { # 기본 경로 NATGW로 변경
  route_table_no         = data.ncloud_route_table.selected.id
  destination_cidr_block = "0.0.0.0/0"
  target_type            = "NATGW"
  target_name            = ncloud_nat_gateway.nat_gateway.name
  target_no              = ncloud_nat_gateway.nat_gateway.id
}



data "ncloud_nks_versions" "version" { # nks 버전 받아오기(KVM)
  hypervisor_code = "KVM"
  filter {
    name = "value"
    values = ["1.31"]
    regex = true
  }
}

resource "ncloud_login_key" "loginkey" { # 로그인 키
  key_name = "k8s-login-key" # 인증키 생성
}


/*

"availableClusterTypes":[
{"label":"10","value":"SVR.VNKS.STAND.C002.M008.NET.SSD.B050.G002"},
{"label":"50","value":"SVR.VNKS.STAND.C004.M016.NET.SSD.B050.G002"}
]
*/

resource "ncloud_nks_cluster" "cluster" { # NKS 클러스터 설치치
  hypervisor_code        = "KVM"
  cluster_type           = "SVR.VNKS.STAND.C002.M008.G003" # node의 최대 개수
  k8s_version            = data.ncloud_nks_versions.version.versions.0.value 
  login_key_name         = ncloud_login_key.loginkey.key_name
  name                   = "terraform-cluster"
  lb_private_subnet_no   = ncloud_subnet.subnet_lb.id
  lb_public_subnet_no    = ncloud_subnet.subnet_lb_pub.id
  kube_network_plugin    = "cilium"
  subnet_no_list         = [ ncloud_subnet.subnet.id ]
  vpc_no                 = ncloud_vpc.vpc.id
  public_network         = false
  zone                   = "KR-1"
}

data "ncloud_nks_server_images" "image"{ # node에 사용할 서버 이미지
  hypervisor_code = "KVM"
  filter {
    name = "label"
    values = ["ubuntu-22.04"]
    regex = true
  }
}

data "ncloud_nks_server_products" "product"{ # 서버 스팩 
  software_code = data.ncloud_nks_server_images.image.images[0].value
  zone = "KR-1"

  filter {
    name = "product_type"
    values = [ "STAND"]
  }

  filter {
    name = "cpu_count"
    values = [ "2"]
  }

  filter {
    name = "memory_size"
    values = [ "8GB" ]
  }
}

/*
│ Error: Status: 400 Bad Request, 
Body: {"message":"Invalid software code(SW.VSVR.OS.LNX64.UBNTU.SVR22.WRKND.G003|23215604)",
"availableOptions":["SW.VSVR.OS.LNX64.UBNTU.SVR2004.WRKND.B050"],"timestamp":"2025-04-10T00:28:58.568Z"}
*/

/*
Error: Status: 400 Bad Request,
 Body: {"message":"Invalid productCode(SW.VSVR.OS.LNX64.UBNTU.SVR22.WRKND.G003)",
 "availableOptions":["SVR.VSVR.HICPU.C032.M064.NET.SSD.B050.G002","SVR.VSVR.STAND.C032.M128.NET.SSD.B050.G002",
 "SVR.VSVR.STAND.C016.M064.NET.SSD.B050.G002","SVR.VSVR.STAND.C008.M032.NET.SSD.B050.G002",
 "SVR.VSVR.STAND.C004.M016.NET.SSD.B050.G002","SVR.VSVR.STAND.C002.M008.NET.SSD.B050.G002",
 "SVR.VSVR.HIMEM.C032.M256.NET.SSD.B050.G002","SVR.VSVR.HIMEM.C016.M128.NET.SSD.B050.G002",
 "SVR.VSVR.HIMEM.C008.M064.NET.SSD.B050.G002","SVR.VSVR.HIMEM.C004.M032.NET.SSD.B050.G002",
 "SVR.VSVR.HIMEM.C002.M016.NET.SSD.B050.G002","SVR.VSVR.HICPU.C016.M032.NET.SSD.B050.G002",
 "SVR.VSVR.HICPU.C008.M016.NET.SSD.B050.G002","SVR.VSVR.HICPU.C004.M008.NET.SSD.B050.G002",
 "SVR.VSVR.HICPU.C002.M004.NET.SSD.B050.G002","SVR.VSVR.GPU.T4.G001.C004.M020.NET.SSD.B050.G001",
 "SVR.VSVR.GPU.T4.G002.C032.M160.NET.SSD.B050.G001","SVR.VSVR.GPU.T4.G002.C016.M080.NET.SSD.B050.G001",
 "SVR.VSVR.GPU.T4.G002.C008.M040.NET.SSD.B050.G001","SVR.VSVR.GPU.T4.G001.C016.M080.NET.SSD.B050.G001",
 "SVR.VSVR.GPU.T4.G001.C008.M040.NET.SSD.B050.G001"],"timestamp":"2025-04-10T01:02:59.577Z"}
│
*/
resource "ncloud_nks_node_pool" "node_pool" { # 노드 생성
  cluster_uuid     = ncloud_nks_cluster.cluster.uuid
  node_pool_name   = "k8s-node-pool"
  node_count       = 2
  software_code    = data.ncloud_nks_server_images.image.images[0].value # 서버 이미지 ex)ubuntu22
  server_spec_code = data.ncloud_nks_server_products.product.products.0.value # 서버 스펙 G.C.M 
  storage_size = 200 # default 100GB
}