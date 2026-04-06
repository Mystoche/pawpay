terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
    }
  }
}

provider "docker" {}

# Network
resource "docker_network" "Devops_net" {
  name = "Devops_network"
}

# Volume (C'est lui qui protège tes données !)
resource "docker_volume" "jenkins_data" {
  name = "jenkins_data"
}

# Image Jenkins
resource "docker_image" "jenkins" {
  name = "jenkins/jenkins:lts"
}

# Container Jenkins
resource "docker_container" "jenkins" {
  name  = "jenkins_server"
  image = docker_image.jenkins.name

  networks_advanced {
    name = docker_network.Devops_net.name
  }

  # --- CONFIGURATION VOLUMES MISE À JOUR ---
  
  volumes {
    volume_name    = docker_volume.jenkins_data.name
    container_path = "/var/jenkins_home"
  }

  # 2. socket Docker
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  # 3. binaire Docker
  volumes {
    host_path      = "/usr/bin/docker"
    container_path = "/usr/bin/docker"
  }

  # ------------------------------------------

  ports {
    internal = 8080
    external = 8080
  }

  ports {
    internal = 50000
    external = 50000
  }

  restart = "always"
  
  # Optionnel : exécuter en root pour éviter les soucis de permissions initiaux
  user = "root" 
}
