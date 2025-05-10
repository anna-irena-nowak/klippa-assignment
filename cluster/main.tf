terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Vnet
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

# Cluster
resource "google_container_cluster" "default" {
  name       = "klippa-assignment"
  location   = var.region
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  enable_autopilot = true
  # versioning and upgrades mode. This is the default
  release_channel {
    channel = "REGULAR"
  }
}

# allow traffic to reach the cluster
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  direction = "INGRESS"

  # enable when security is in place
  # source_ranges = ["0.0.0.0/0"]

  # my IP
  source_ranges = ["84.105.69.90/32"]
}