
resource "helm_release" "druid_cluster" {
  name             = "druid-cluster"
  chart            = var.DRUID_CLUSTER_CHART
  namespace        = var.DRUID_NAMESPACE
  create_namespace = true
  depends_on       = [helm_release.druid_operator]
  wait_for_jobs    = true
  timeout           = 3000  
  values = [
    templatefile("../../helm_charts/druid-cluster/values.yaml",
      {
        druid_namespace = var.DRUID_NAMESPACE
        druid_user  = "druid"
        druid_password  = "druid"
        druid_worker_capacity = var.DRUID_MIDDLE_MANAGER_WORKER_NODES
        deployment_stage = var.STAGE
      }
    )
  ]
}



data "kubernetes_service" "druid" {
  metadata {
    namespace = "druid-raw"
    name = "druid-cluster-zookeeper"
  }
  depends_on       = [helm_release.druid_cluster, helm_release.druid_operator]
}

resource "helm_release" "druid_operator" {
  name             = "druid-operator"
  chart            =  var.DRUID_OPERATOR_CHART
  create_namespace = true
  namespace        = var.DRUID_NAMESPACE
  wait_for_jobs    = true
  depends_on = [
    kind_cluster.one-click
  ]
}

resource "helm_release" "druid_cluster" {
  name             = "druid-cluster"
  chart            = var.DRUID_CLUSTER_CHART
  namespace        = var.DRUID_NAMESPACE
  create_namespace = true
  depends_on       = [helm_release.druid_operator, helm_release.postgres]
  wait_for_jobs    = true
  timeout           = 3000  
  values = [
    templatefile("../../helm_charts/druid-cluster/values.yaml",
      {
        druid_namespace = var.DRUID_NAMESPACE
        druid_user  = "druid"
        druid_password  = "druid"
        druid_worker_capacity = var.DRUID_MIDDLE_MANAGER_WORKER_CAPACITY
        env = var.STAGE
        storage_class_name = "local-path"
      }
    )
  ]
}


