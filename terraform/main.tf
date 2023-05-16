terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "network"
}

resource "yandex_vpc_subnet" "public-segment" {
  name           = "public-segment"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "private-segment-a" {
  name           = "private-segment-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_subnet" "private-segment-b" {
  name           = "private-segment-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}

resource "yandex_vpc_security_group" "secure-bastion-sg" {
  name       = "secure-bastion-sg"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "internal-bastion-sg" {
  name       = "internal-bastion-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "TCP"
    description    = "ssh"
    port           = 22
    v4_cidr_blocks = [yandex_vpc_subnet.private-segment-a.v4_cidr_blocks[0], yandex_vpc_subnet.private-segment-b.v4_cidr_blocks[0], yandex_vpc_subnet.public-segment.v4_cidr_blocks[0]]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = [var.bastion_internal_ip_v4_cidr_blocks[0]]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "alb-sg" {
  name       = "alb-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol       = "TCP"
    description    = "healthchecks"
    v4_cidr_blocks = ["198.18.235.0/24", "198.18.248.0/24"]
    port           = 30080
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "grafana-sg" {
  name       = "grafana-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "prometheus-sg" {
  name       = "prometheus-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9090
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "node-exporter-sg" {
  name       = "node-exporter-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = [var.prometheus_ip_v4_cidr_blocks[0]]
    port           = 9100
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = [var.prometheus_ip_v4_cidr_blocks[0]]
    port           = 4040
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "kibana-sg" {
  name       = "kibana-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "kibana"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "elastic-sg" {
  name       = "elastic-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "elastic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9200
  }

  ingress {
    protocol       = "TCP"
    description    = "elastic"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 9300
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }
}

resource "yandex_vpc_security_group" "alb-vm-sg" {
  name       = "alb-vm-sg"
  network_id = yandex_vpc_network.network.id

  egress {
    protocol       = "ANY"
    description    = "any"
    security_group_id = yandex_vpc_security_group.prometheus-sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.alb-sg.id
    port              = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from jump server"
    security_group_id = yandex_vpc_security_group.internal-bastion-sg.id
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from prometheus server"
    security_group_id = yandex_vpc_security_group.prometheus-sg.id
    port           = 4040
  }

  ingress {
    protocol       = "TCP"
    description    = "traffic from prometheus server"
    security_group_id = yandex_vpc_security_group.prometheus-sg.id
    port           = 9100
  }
}

resource "yandex_compute_image" "lemp" {
  source_family = "lemp"
}

data "yandex_compute_image" "container-optimized-image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance_group" "alb-vm-group" {
  name               = "alb-vm-group"
  folder_id          = var.folder_id
  service_account_id = var.service_account_id
  instance_template {
    platform_id        = "standard-v2"
    service_account_id = var.service_account_id
    resources {
      core_fraction = 5
      memory        = 1
      cores         = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = yandex_compute_image.lemp.id
        type     = "network-hdd"
        size     = 3
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.network.id
      subnet_ids         = [yandex_vpc_subnet.private-segment-a.id, yandex_vpc_subnet.private-segment-b.id]
      nat                = false
      security_group_ids = [yandex_vpc_security_group.alb-vm-sg.id, yandex_vpc_security_group.node-exporter-sg.id]
    }

    metadata = {
      user-data = "${file("./meta.txt")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
    /*auto_scale {
      initial_size           = 2
      max_size               = 3
      min_zone_size          = 1
      measurement_duration   = 60
      warmup_duration        = 60
      stabilization_duration = 120
      cpu_utilization_target = 75
    }*/
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  application_load_balancer {
    target_group_name = "alb-tg"
  }
}

resource "yandex_alb_backend_group" "alb-bg" {
  name = "alb-bg"

  http_backend {
    name             = "backend-1"
    port             = 80
    target_group_ids = [yandex_compute_instance_group.alb-vm-group.application_load_balancer.0.target_group_id]
    healthcheck {
      timeout          = "10s"
      interval         = "2s"
      healthcheck_port = 80
      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "alb-router" {
  name = "alb-router"
}

resource "yandex_alb_virtual_host" "alb-host" {
  name           = "alb-host"
  http_router_id = yandex_alb_http_router.alb-router.id
  /*authority      = ["alb-example.com"]*/
  route {
    name = "route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.alb-bg.id
      }
    }
  }
}

resource "yandex_alb_load_balancer" "alb-1" {
  name               = "alb-1"
  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.alb-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public-segment.id
    }
  }

  listener {
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.alb-router.id
      }
    }
  }
}

resource "yandex_compute_instance" "jump" {
  name = "jump"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
/*      image_id = "fd8ofaiv60813cil4pn4"*/
      image_id = "fd8lv2ar4kaq92jiihem"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-segment.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.secure-bastion-sg.id, yandex_vpc_security_group.internal-bastion-sg.id]
    ip_address         = var.bastion_internal_ip_address
  }
/*
  network_interface {
    subnet_id          = yandex_vpc_subnet.private-segment-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.internal-bastion-sg.id]
    ip_address         = var.bastion_internal_ip_address
  }
*/
    metadata = {
    user-data = "${file("./meta.txt")}"
  }

}

resource "yandex_compute_instance" "elastic" {
  name = "elastic"

  resources {
    cores  = 4
    memory = 8
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-segment-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elastic-sg.id]
    ip_address         = var.elastic_ip_address
  }

  metadata = {
    user-data = "${file("./meta-elastic.txt")}"
    docker-compose = "${file("./docker/docker-compose-elastic.yml")}"
  }
}

resource "yandex_compute_instance" "kibana" {
  name = "kibana"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
      type     = "network-ssd"
      size     = 30
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-segment.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
    docker-compose = "${file("./docker/docker-compose-kibana.yml")}"
  }
}

resource "yandex_compute_instance" "prometheus" {
  name = "prometheus"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8r9ntkrnrn46fkh0e4"
      type     = "network-ssd"
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-segment-a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.prometheus-sg.id]
    ip_address         = var.prometheus_ip_address
  }

  metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

resource "yandex_compute_instance" "grafana" {
  name = "grafana"

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.container-optimized-image.id
      type     = "network-ssd"
      size     = 30
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.public-segment.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.grafana-sg.id]
  }
  resources {
    cores = 2
    memory = 2
  }
  metadata = {
    docker-compose = "${file("./docker/docker-compose-grafana.yml")}"
    user-data = "${file("./meta.txt")}"
  }
}

data "template_file" "inventory" {
  template = file("./_templates/inventory.tftpl")
  vars = {
    user                 = "admin"
    groupname_Web        = "webServer"
    groupname_ELK        = "elastic"
    groupname_Prometheus = "prometheus"
    groupname_Bastion    = "bastion"
    groupname_Grafana    = "grafana"
    groupname_Kibana     = "kibana"
    ip_Web01             = ""
    ip_Web02             = ""
    ip_ELK               = var.elastic_ip_address
    ip_Prometheus        = var.prometheus_ip_address
    ip_Bastion           = yandex_compute_instance.jump.network_interface.0.nat_ip_address
    ip_Grafana           = yandex_compute_instance.grafana.network_interface.0.ip_address
    ip_Kibana            = yandex_compute_instance.kibana.network_interface.0.ip_address
  }
}

resource "local_file" "save_inventory" {
  content  = data.template_file.inventory.rendered
  filename = "./inventory.ini"
}