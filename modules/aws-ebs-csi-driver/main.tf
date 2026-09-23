resource "helm_release" "aws_ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = var.chart_version

  values = [
    yamlencode({
      controller = {
        region          = var.aws_region
        extraVolumeTags = var.aws_tags
      }
    })
  ]
}
