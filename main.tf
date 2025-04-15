module "nks" {
    source = "./modules/nks"
    providers = {
      ncloud = ncloud
    }
}

module "mysql" {
  source = "./modules/mysql"
  providers = {
    ncloud = ncloud
  }
  subnet_no = module.nks.subnet_no
}

module "bastion" {
  source = "./modules/bastion"
  providers = {
    ncloud = ncloud
  }
  vpc_no = module.nks.vpc_no
  vpc_acl_no = module.nks.vpc_acl_no
}
