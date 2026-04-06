terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# SonarQube

resource "docker_image" "sonarqube" {
  name = "sonarqube:community"
}

resource "docker_container" "sonarqube" {
  name  = "sonarqube-custom"
  image = docker_image.sonarqube.image_id

  ports {
    internal = 9000
    external = 9000
  }
}


# Trivy (OFFICIEL)

resource "docker_image" "trivy" {
  name = "aquasec/trivy:0.69.3"
}

resource "docker_container" "trivy_scan" {
  name  = "trivy-scan"
  image = docker_image.trivy.image_id

  # Forcer un shell pour rester actif
  entrypoint = ["sh", "-c"]
  command    = ["while true; do sleep 1000; done"]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  volumes {
    host_path      = "${pathexpand("~")}/Library/Caches"
    container_path = "/root/.cache"
  }

  must_run = true
}
