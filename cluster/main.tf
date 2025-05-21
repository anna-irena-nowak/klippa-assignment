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
  name       = var.cluster_name
  location   = var.zone
  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true
  initial_node_count       = 1

  # versioning and upgrades mode. This is the default
  release_channel {
    channel = "REGULAR"
  }

  # enable Cloud Logging
  logging_service    = "logging.googleapis.com/kubernetes"
  # enable Cloud Monitoring
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  ip_allocation_policy {}

  deletion_protection = false
}

# Node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  cluster    = google_container_cluster.default.name
  location   = var.zone

  autoscaling {
    min_node_count = 0
    max_node_count = 4
  }

  management {
    auto_upgrade = true # auto-upgrade VMs
    auto_repair  = true # monitor node health and reboot if needed
  }

  node_config {
    machine_type = "e2-medium" # 2 CPUs, 4GB RAM

    oauth_scopes = [
      # which APIs the VMs are allowed to access via the default service account
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "dev"
    }
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

# reserve a static IP
resource "google_compute_address" "static_ip" {
  name   = "${var.cluster_name}-ip"
  region = var.region
}