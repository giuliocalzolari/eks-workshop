# Guest Book App
resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
    namespace = "${var.namespace}"

    labels = {
      app  = "guestbook"
      name = "frontend"
      stage = "${var.stage}"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app  = "guestbook"
        tier = "frontend"
        stage = "${var.stage}"
      }
    }

    template {
      metadata {
        labels = {
          app  = "guestbook"
          tier = "frontend"
          stage = "${var.stage}"
        }
      }

      spec {

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1

              pod_affinity_term {
                topology_key = "failure-domain.beta.kubernetes.io/zone"
                label_selector {
                  match_expressions {
                    key      = "tier"
                    operator = "In"
                    values   = ["frontend"]
                  }
                }
              }
            }
          }
        }

        container {
          image = "gcr.io/google-samples/gb-frontend:v4"
          name  = "php-redis"

          resources {
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          env {
            name  = "GET_HOSTS_FROM"
            value = "dns"
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend-svc" {
  metadata {
    name = "frontend"
    namespace = "${var.namespace}"
    labels = {
      app  = "guestbook"
      name = "frontend"
      stage = "${var.stage}"
    }

    # annotations {
    #   "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = "${aws_acm_certificate.cert.certificate_arn}"
    # }
  }

  spec {
    selector = {
      app  = "guestbook"
      tier = "frontend"
      stage = "${var.stage}"
    }

    port {
      port = 80
    }

    # port {
    #   port = 443


    # }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "redis-master" {
  metadata {
    name = "redis-master"
    namespace = "${var.namespace}"

    labels = {
      app  = "redis"
      role = "master"
      name = "backend"
      stage = "${var.stage}"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app  = "redis"
        role = "master"
        name = "backend"
        stage = "${var.stage}"
      }
    }

    template {
      metadata {
        labels = {
          app  = "redis"
          role = "master"
          name = "backend"
          stage = "${var.stage}"
        }
      }

      spec {
        container {
          image = "k8s.gcr.io/redis:e2e"
          name  = "master"

          resources {
            requests {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis-master-svc" {
  metadata {
    name = "redis-master"
    namespace = "${var.namespace}"

    labels = {
      app  = "redis"
      role = "master"
      name = "backend"
      stage = "${var.stage}"
    }
  }

  spec {
    selector = {
      app  = "redis"
      role = "master"
      name = "backend"
      stage = "${var.stage}"
    }

    port {
      port        = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_deployment" "redis-slave" {
  metadata {
    name = "redis-slave"
    namespace = "${var.namespace}"

    labels = {
      app  = "redis"
      role = "slave"
      name = "backend"
      stage = "${var.stage}"
    }
  }

  spec {
    replicas               = 3
    revision_history_limit = 0

    selector {
      match_labels = {
        app  = "redis"
        role = "slave"
        name = "backend"
        stage = "${var.stage}"
      }
    }

    template {
      metadata {
        labels = {
          app  = "redis"
          role = "slave"
          name = "backend"
          stage = "${var.stage}"
        }
      }

      spec {

        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 1

              pod_affinity_term {
                topology_key = "failure-domain.beta.kubernetes.io/zone"
                label_selector {
                  match_expressions {
                    key      = "role"
                    operator = "In"
                    values   = ["slave"]
                  }
                }
              }
            }
          }
        }

        container {
          image = "gcr.io/google_samples/gb-redisslave:v1"
          name  = "slave"

          resources {
            requests {
              cpu    = "100m"
              memory = "100Mi"
            }
          }

          env {
            name  = "GET_HOSTS_FROM"
            value = "dns"
          }

          port {
            container_port = 6379
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis-slave-svc" {
  metadata {
    name = "redis-slave"
    namespace = "${var.namespace}"

    labels = {
      app  = "redis"
      role = "slave"
      name = "backend"
      stage = "${var.stage}"
    }
  }

  spec {
    selector = {
      app  = "redis"
      role = "slave"
      name = "backend"
      stage = "${var.stage}"
    }

    port {
      port = 6379
    }
  }
}
