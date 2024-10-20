# -------------- POSTGRES PROVIDER ----------------------------

provider "postgresql" {
  host             = aws_db_instance.osm_rds.address
  username         = aws_db_instance.osm_rds.username
  password         = aws_db_instance.osm_rds.password
  database         = var.db_name
  port             = 5432
  expected_version = "15.5"
  sslmode          = "require"
  connect_timeout  = 600
}

# -------------- RESOURCES ------------------------------------

resource "postgresql_extension" "postgis_extension" {
  name = "postgis"
}

resource "postgresql_extension" "hstore_extension" {
  name = "hstore"
}

resource "postgresql_schema" "lviv_schema" {
  name = "lviv"
}

resource "postgresql_schema" "kyiv_schema" {
  name = "kyiv"
}

resource "terraform_data" "download_osm_data_lviv" {
  depends_on = [postgresql_schema.lviv_schema, postgresql_extension.postgis_extension, postgresql_extension.hstore_extension]
  provisioner "local-exec" {
    when        = create
    working_dir = "../database/scripts/"
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      chmod +x download-osm-lviv.sh
      ./download-osm-lviv.sh
    EOT
    environment = {
      DB_NAME     = nonsensitive(var.db_name)
      DB_ADDRESS  = nonsensitive(aws_db_instance.osm_rds.address)
      DB_USERNAME = nonsensitive(aws_db_instance.osm_rds.username)
      PGPASSWORD  = nonsensitive(aws_db_instance.osm_rds.password)
      SCHEMA_NAME = nonsensitive(postgresql_schema.lviv_schema)
    }
  }
}

resource "postgresql_function" "get_places_nearby_lviv" {
  depends_on = [terraform_data.download_osm_data_lviv]

  name     = "get_places_nearby_lviv"
  language = "plpgsql"
  returns  = "TABLE(way text, name text, amenity text, tags hstore)"

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
        SET search_path TO ${postgresql_schema.lviv_schema};
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

resource "terraform_data" "download_osm_data_kyiv" {
  depends_on = [postgresql_schema.kyiv_schema, postgresql_extension.postgis_extension, postgresql_extension.hstore_extension]
  provisioner "local-exec" {
    when        = create
    working_dir = "../database/scripts/"
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      chmod +x download-osm-kyiv.sh
      ./download-osm-kyiv.sh
    EOT
    environment = {
      DB_NAME     = nonsensitive(var.db_name)
      DB_ADDRESS  = nonsensitive(aws_db_instance.osm_rds.address)
      DB_USERNAME = nonsensitive(aws_db_instance.osm_rds.username)
      PGPASSWORD  = nonsensitive(aws_db_instance.osm_rds.password)
      SCHEMA_NAME = nonsensitive(postgresql_schema.kyiv_schema)
    }
  }
}

resource "postgresql_function" "get_places_nearby_kyiv" {
  depends_on = [terraform_data.download_osm_data_kyiv]

  name     = "get_places_nearby_kyiv"
  language = "plpgsql"
  returns  = "TABLE(way text, name text, amenity text, tags hstore)"

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
        SET search_path TO ${postgresql_schema.kyiv_schema};
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
            and poly.name = 'Київ'
            AND ST_DWithin(
                p.way,
                ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography,
                distance
            );
    END;
  EOT
}
