# Guest Book App
resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"

    labels {
      app  = "guestbook"
      name = "frontend"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels {
        app  = "guestbook"
        tier = "frontend"
      }
    }

    template {
      metadata {
        labels {
          app  = "guestbook"
          tier = "frontend"
        }
      }

      spec {
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

    labels {
      app  = "guestbook"
      name = "frontend"
    }
  }

  spec {
    selector {
      app  = "guestbook"
      tier = "frontend"
    }

    port {
      port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "redis-master" {
  metadata {
    name = "redis-master"

    labels {
      app  = "redis"
      role = "master"
      name = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels {
        app  = "redis"
        role = "master"
        name = "backend"
      }
    }

    template {
      metadata {
        labels {
          app  = "redis"
          role = "master"
          name = "backend"
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

    labels {
      app  = "redis"
      role = "master"
      name = "backend"
    }
  }

  spec {
    selector {
      app  = "redis"
      role = "master"
      name = "backend"
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

    labels {
      app  = "redis"
      role = "slave"
      name = "backend"
    }
  }

  spec {
    replicas               = 3
    revision_history_limit = 0

    selector {
      match_labels {
        app  = "redis"
        role = "slave"
        name = "backend"
      }
    }

    template {
      metadata {
        labels {
          app  = "redis"
          role = "slave"
          name = "backend"
        }
      }

      spec {
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

    labels {
      app  = "redis"
      role = "slave"
      name = "backend"
    }
  }

  spec {
    selector {
      app  = "redis"
      role = "slave"
      name = "backend"
    }

    port {
      port = 6379
    }
  }
}
