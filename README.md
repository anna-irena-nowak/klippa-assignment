# Homework assignment for Klippa

The service is running at https://35-204-29-127.nip.io.
Exposed endpoints:
  - livez
  - render
  
Cluster itself is provisioned via Terraform, but the services are deployed traditionally with kubectl/helm without automation.
Authentication requires a GitHub account.
SSL certificates are provided by letsencrypt.org via cert-manager.
Prometheus + Grafana combo provide observability, with additional metrics scraped from /metrics endpoint exposed by the service.

Also have a look at the [deployment notes](deployment-notes.md)
