# -------------- POSTGRES PROVIDER ----------------------------

provider "postgresql" {
  host             = aws_db_instance.osm_rds.address
  username         = aws_db_instance.osm_rds.username
  password         = aws_db_instance.osm_rds.password
  port             = 5432
  database         = "postgres"
  expected_version = "15.5"
  sslmode          = "require"
  connect_timeout  = 15
}

# -------------- RESOURCES ------------------------------------

resource "postgresql_extension" "postgis_extension" {
  name = "postgis"
}

resource "postgresql_extension" "hstore_extension" {
  name = "hstore"
}

resource "terraform_data" "download_osm_data" {
  provisioner "local-exec" {
    working_dir = "../database/"
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      chmod +x download-osm-ukraine.sh
      ./download-osm-ukraine.sh
    EOT
    environment = {
      DB_NAME     = nonsensitive(aws_db_instance.osm_rds.identifier)
      DB_ADDRESS  = nonsensitive(aws_db_instance.osm_rds.address)
      DB_USERNAME = nonsensitive(aws_db_instance.osm_rds.username)
      PGPASS      = nonsensitive(aws_db_instance.osm_rds.password)
    }
  }
}
