output "reserved_ip" {
  description = "Reserved static IP"
  value = google_compute_address.static_ip.address
}