# -------------- POSTGRES PROVIDER ----------------------------

provider "postgresql" {
  host             = aws_db_instance.osm_rds.address
  username         = aws_db_instance.osm_rds.username
  password         = aws_db_instance.osm_rds.password
  database         = var.db_name
  port             = 5432
  expected_version = "15.5"
  sslmode          = "require"
  connect_timeout  = 60000
}

# -------------- RESOURCES ------------------------------------

resource "postgresql_extension" "postgis_extension" {
  name = "postgis"
}

resource "postgresql_extension" "hstore_extension" {
  name = "hstore"
}

resource "terraform_data" "download_osm_data" {
  depends_on = [postgresql_extension.postgis_extension, postgresql_extension.hstore_extension]
  provisioner "local-exec" {
    when        = create
    working_dir = "../database/scripts/"
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      chmod +x download-osm-ukraine.sh
      ./download-osm-ukraine.sh
    EOT
    environment = {
      DB_NAME     = nonsensitive(var.db_name)
      DB_ADDRESS  = nonsensitive(aws_db_instance.osm_rds.address)
      DB_USERNAME = nonsensitive(aws_db_instance.osm_rds.username)
      PGPASSWORD  = nonsensitive(aws_db_instance.osm_rds.password)
    }
  }
}

resource "postgresql_function" "get_places_nearby" {
  depends_on = [terraform_data.download_osm_data]

  name     = "get_places_nearby"
  language = "plpgsql"
  returns  = "TABLE(way text, name text, p.amenity, tags hstore)"

  arg {
    name = "lon"
    type = "float"
  }

  arg {
    name = "lat"
    type = "float"
  }

  arg {
    name = "distance"
    type = "int"
  }

  arg {
    name = "amenities"
    type = "text[]"
  }

  body = <<-EOT
    BEGIN
        RETURN QUERY
        SELECT DISTINCT
            ST_AsText(p.way),
            p.name,
            p.amenity,
            p.tags
        FROM
            planet_osm_point p
        JOIN
            planet_osm_polygon poly ON ST_Contains(poly.way, p.way)
        WHERE
            p.amenity = ANY(amenities)
            AND p.name IS NOT NULL
            AND poly.admin_level = '6'
            AND poly.name = 'Львівський район'
            AND ST_DWithin(
                p.way,
                ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
                distance
            );
    END;
  EOT
}
