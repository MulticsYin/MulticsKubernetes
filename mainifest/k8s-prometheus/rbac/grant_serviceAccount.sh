#!/bin/sh

# grant cluster-admin to monitoring:prometheus-k8s (rbac)
kubectl create clusterrolebinding add_clusteradmin_prometheus --clusterrole=cluster-admin --serviceaccount=monitoring:prometheus-k8s

exit 0
