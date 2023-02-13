terraform {

  required_version = ">= 1.1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.42.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstorage"
    storage_account_name = "tfstatestorage23"
    container_name       = "tfstatecontainer"
    key                  = "K6uB8hVaKZJKce1xnUnCgVg+w8lYbny3HPwQ2qCdjuAf/znQQk1YESSwVoth9L1gn0WGhwdiHhPD+AStRsLRCA=="
  }
}

provider "azurerm" {
  features {}
}


############################################
# Resource Group
############################################

module "c001_dss_rg" {
  source      = "git@github.com:praveen2391/dss-cns.git//resource-group"
  rg-name     = var.dss-rg-name
  rg-location = var.dss-rg-location
  environment = var.dss-environment
}

############################################
# Virtual Network
############################################

module "c001_dss_vn" {
  source        = "git@github.com:praveen2391/dss-cns.git//virtual-network"
  vn-name       = var.dss-vn-name
  rg-location   = var.dss-rg-location
  rg-name       = var.dss-rg-name
  address_space = var.address_space
  dns-servers   = var.dss-dns-servers
  environment   = var.dss-environment

  depends_on = [module.c001_dss_rg]
}


############################################
# Subnet
############################################

module "c001_dss_subnet" {
  source           = "git@github.com:praveen2391/dss-cns.git//subnet"
  subnet-name      = var.subnet-name
  rg-name          = var.dss-rg-name
  vn-name          = var.dss-vn-name
  address_prefixes = var.address_prefixes

  depends_on = [module.c001_dss_vn]
}

############################################
# Storage-account
############################################

module "c001_dss_storageaccount" {
  source                   = "git@github.com:praveen2391/dss-cns.git//storage-account"
  sa-name                  = var.dss-sa-name
  rg-name                  = var.dss-rg-name
  location                 = var.dss-rg-location
  account-tier             = var.account-tier
  account-replication-type = var.account-replication-type
  environment              = var.dss-environment

  depends_on = [module.c001_dss_rg]
}

############################################
# Storage-container
############################################

module "c001_dss_storagecontainer" {
  source           = "git@github.com:praveen2391/dss-cns.git//storage-container"
  storage-cnt-name = var.dss-storage-cnt-name
  sa-name          = var.dss-sa-name
  # sa-name = module.c001_dss_storageaccount.dss-sa-name
  container-access-type = var.dss-container-access-type
}

############################################
# Storage-container blob
############################################

module "c001_dss_storagecontainer_blob" {
  source              = "git@github.com:praveen2391/dss-cns.git//storage-blob"
  storage-blob-name   = var.dss-storage-blob-name
  sa-name             = var.dss-sa-name
  storage-cnt-name    = var.dss-storage-cnt-name
  storage-blob-type   = var.dss-storage-blob-type
  storage-blob-source = var.dss-storage-blob-source
}


############################################
# Storage-account Private-endpt
############################################

module "c001_dss_sa_privateendpt" {
  source                              = "git@github.com:praveen2391/dss-cns.git//privateendpt"
  privateendpt-name                = var.dss-sa-privateendpt-name
  privateendpt-location            = var.dss-rg-location
  privateendpt-rg-name             = var.dss-rg-name
  privateendpt-subnetid            = module.c001_dss_subnet.subnet-id
  pvtendpt-pvt-svc-cnt-name        = var.dss-sa-pvtendpt-pvt-svc-cnt-name
  pvtendpt-pvt-svc-cnt-resource-id = module.c001_dss_storageaccount.sa-id
  pvtendpt-pvt-svc-cnt-manual-cnt  = var.dss-sa-pvtendpt-pvt-svc-cnt-manual-cnt
  # subresource_names = ["blob"] 
  pvtendpt-pvt-svc-cnt-subresource-names = var.dss-sa-pvtendpt-pvt-svc-cnt-subresource-names
}


############################################
# Postgres-sql server
############################################

module "c001_dss_postgresql" {
  source           = "git@github.com:praveen2391/dss-cns.git//postgresql"
  postgresql-name              = var.dss-postgresql-name
  location                     = var.dss-rg-location
  rg-name                      = var.dss-rg-name
  storage-mb                   = var.dss-storage-mb
  backup-retention-days        = var.dss-backup-retention-days
  geo-redundant-backup-enabled = var.dss-geo-redundant-backup-enabled
  auto-grow-enabled            = var.dss-auto-grow-enabled
  administrator-login          = var.dss-administrator-login
  administrator-login-password = var.dss-administrator-login-password
  # pg-version = var.pg-version
  # version                 = "11"
  ssl-enforcement-enabled = var.dss-ssl-enforcement-enabled

}

############################################
# Postgres-sql DB
############################################

module "c001_dss_postgresql_db" {
  source           = "git@github.com:praveen2391/dss-cns.git//postgresql-db"
  postgresql-db-name = var.dss-postgresql-db-name
  rg-name = var.dss-rg-name
  server-name = var.dss-postgresql-name
  charset = var.dss-charset
  collation = var.dss-collation
}


module "c001_dss_pg_privateendpt" {
  source                              = "git@github.com:praveen2391/dss-cns.git//privateendpt"
  privateendpt-name                = var.dss-pg-privateendpt-name
  privateendpt-location            = var.dss-rg-location
  privateendpt-rg-name             = var.dss-rg-name
  privateendpt-subnetid            = module.c001_dss_subnet.subnet-id
  pvtendpt-pvt-svc-cnt-name        = var.dss-pg-pvtendpt-pvt-svc-cnt-name
  pvtendpt-pvt-svc-cnt-resource-id = module.c001_dss_postgresql.postgresql-id
  pvtendpt-pvt-svc-cnt-manual-cnt  = var.dss-pg-pvtendpt-pvt-svc-cnt-manual-cnt
  # subresource_names = ["blob"] 
  pvtendpt-pvt-svc-cnt-subresource-names = var.dss-pg-pvtendpt-pvt-svc-cnt-subresource-names
}







