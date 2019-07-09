resource "kubernetes_secret" "ks_secret" {
  metadata {
    name      = "kubernetes-dashboard-certs"
    namespace = "kube-system"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  type = "Opaque"
}

resource "kubernetes_service_account" "ks_service_account" {
  automount_service_account_token = true

  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kube-system"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }
}

resource "kubernetes_role" "ks_role" {
  metadata {
    namespace = "kube-system"
    name      = "kubernetes-dashboard-minimal"

    labels = {
      name = "kubernetes-dashboard-minimal"
    }
  }

  # Allow Dashboard to create 'kubernetes-dashboard-key-holder' secret.
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }

  # Allow Dashboard to create 'kubernetes-dashboard-settings' config map.
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create"]
  }

  # Allow Dashboard to get, update and delete Dashboard exclusive secrets.
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
    verbs          = ["get", "update", "delete"]
  }

  # Allow Dashboard to get and update 'kubernetes-dashboard-settings' config map.
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
    verbs          = ["get", "update"]
  }

  # Allow Dashboard to get metrics from heapster.
  rule {
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster"]
    verbs          = ["proxy"]
  }

  rule {
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:"]
    verbs          = ["get"]
  }
}

resource "kubernetes_role_binding" "ks_role_binding" {
  metadata {
    name      = "kubernetes-dashboard-minimal"
    namespace = "kube-system"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "kubernetes-dashboard-minimal"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "ks_dashboard_deployment" {
  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kube-system"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 10

    selector {
      match_labels = {
        k8s-app = "kubernetes-dashboard"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "kubernetes-dashboard"
        }
      }

      spec {
        container {
          image = "k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1"
          name  = "kubernetes-dashboard"

          port {
            container_port = 8443
          }

          args = ["--auto-generate-certificates"]

          volume_mount {
            name       = "kubernetes-dashboard-certs"
            mount_path = "/certs"
          }

          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              scheme = "HTTPS"
              path   = "/"
              port   = "443"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 30
          }

          # toleration {
          #   key  = "node-role.kubernetes.io/master"
          #   effect = "NoSchedule"
          # }
        }

        service_account_name            = "kubernetes-dashboard"
        automount_service_account_token = true
        volume {
          name = "kubernetes-dashboard-certs"

          secret {
            secret_name = "kubernetes-dashboard-certs"
          }
        }

        volume {
          name = "tmp-volume"
        }
      }
    }
  }
}


resource "kubernetes_service" "kv_dashboard_svc" {
  metadata {
    namespace = "kube-system"
    name      = "kubernetes-dashboard"

    labels = {
      k8s-app = "kubernetes-dashboard"
    }
  }

  spec {
    selector = {
      k8s-app = "kubernetes-dashboard"
    }

    port {
      port        = 443
      target_port = 8443
    }
  }
}

# # resource "null_resource" "install_dashboard" {
# #   provisioner "local-exec" {
# #     command = "kubectl apply -f kubernetes-dashboard.yaml"

# #     environment {
# #       KUBECONFIG = "${module.eks-cluster.kubeconfig_filename}"
# #     }
# #   }
# # }
