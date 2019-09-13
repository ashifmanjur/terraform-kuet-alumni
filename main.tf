provider "google" {
  version     = "~> 2.14"
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

//resource "google_compute_network" "vpc_network" {
//  name = "terraform-network"
//}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = var.machine_types[var.environment]
  tags         = ["web", "dev", "allow-ssh"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = module.network.network_name
    subnetwork = module.network.subnets_names[0]

    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }
}

resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

# New resource for the storage bucket our application will use.
resource "google_storage_bucket" "example_bucket" {
  name     = "terraform-example-bucket-ashif-20190912"
  location = "US"

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

# Create a new instance that uses the bucket
resource "google_compute_instance" "another_instance" {
  # Tells Terraform that this VM instance must be created only after the
  # storage bucket has been created.
  depends_on = [google_storage_bucket.example_bucket]
  name         = "terraform-instance-2"
  machine_type = "f1-micro"
  tags = ["allow-ssh"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network = module.network.network_name
    subnetwork = module.network.subnets_names[0]

    access_config {
    }
  }
}

module "network" {
  source  = "terraform-google-modules/network/google"
  version = "1.1.0"

  network_name = "terraform-vpc-network"
  project_id   = var.project

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.20.0.0/22"
      subnet_region = var.region
    },
    {
      subnet_name   = "subnet-02"
      subnet_ip     = "10.21.0.0/22"
      subnet_region = var.region

      subnet_private_access = "true"
    },
  ]

  secondary_ranges = {
    subnet-01 = []
    subnet-02 = []
  }
}

resource "google_compute_firewall" "internal" {
  name    = "production-firewall-internal"
  project = var.project
  network = module.network.network_name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  source_ranges = ["10.20.0.0/22", "10.21.0.0/22"]
}


resource "google_compute_firewall" "production_ssh" {
  name    = "production-firewall-allow-ssh"
  network = module.network.network_name
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["allow-ssh"]
}


