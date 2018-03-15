# create kubernetes DNS addon
kubectl create -f .
# check
kubectl exec -ti busybox -- nslookup kubernetes.default

More information see: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
