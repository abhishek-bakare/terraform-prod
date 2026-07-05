# argocd
resource "helm_release" "argocd" {
    name = "argocd"
    namespace = "argocd"
    repository = "https://argoproj.github.io/argo-helm"
    chart = "argo-cd"
    create_namespace = true
    version = "7.3.11"

    values = [
        yamlencode({
            # argocd will deployed on Karp nodes
            global = {
                nodeSelector = {
                    "karpenter.sh/nodepool" = "nodepool-aws-karp"
                    "karpenter.sh/capacity-type" = "on-demand"
                }
            }

            # tells argocd to disable native TLS termination and serve via HTTP instead of HTTPS
            server = {
                service = {
                    type = "ClusterIP"
                }
                extraArgs = ["--insecure"]
            }
        })
    ]
}