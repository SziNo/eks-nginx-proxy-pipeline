# Számított és közös értékek, amelyeket a modulhívások használnak.
locals {
  # A két alkalmazás neve: ebből lesznek az ECR repók.
  # A CI mátrixa (_build.yml) és a scripts/build-push.sh ugyanezeket a neveket használja.
  services = ["service-a", "service-b"]

  # Az LB Controller Helm release namespace-e. Két helyen kell: itt települ a chart, és a
  # terraform-plan role csak ebben a namespace-ben olvashat (a Helm itt tárolja a release-t).
  lb_controller_namespace = "kube-system"
}