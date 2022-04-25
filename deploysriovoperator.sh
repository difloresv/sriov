#!/bin/bash -x

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${DIR}/../ocp-globals.sh

echo "Documentation is here https://docs.openshift.com/container-platform/4.4/networking/hardware_networks/about-sriov.html"
echo "Also see https://bugzilla.redhat.com/show_bug.cgi?id=1849825"

echo "Tagging all worker nodes as sriov capable"
for node in $(oc get nodes | awk '/worker/ {print $1}'); do
	oc label node $node feature.node.kubernetes.io/network-sriov.capable="true"
done

echo "Creating sriov namespace"
cat <<'EOF'> sriov-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-sriov-network-operator
  annotations:
    workload.openshift.io/allowed: management
EOF
oc apply -f sriov-namespace.yaml

echo "Creating operator group"
cat <<'EOF'> sriov-operatorgroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: sriov-network-operators
  namespace: openshift-sriov-network-operator
spec:
  targetNamespaces:
  - openshift-sriov-network-operator
EOF
oc apply -f sriov-operatorgroup.yaml

echo "Creating subscription with correct channel"
cat <<'EOF'> sriov-sub.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sriov-network-operator-subscription
  namespace: openshift-sriov-network-operator
spec:
  channel: "CHANNELVERSION"
  name: sriov-network-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
chanver=$(oc get packagemanifest sriov-network-operator -n openshift-marketplace -o json | jq -r --arg OCP_MAJOR_VERSION $OCP_MAJOR_VERSION '.status.channels[] | select(.name==$OCP_MAJOR_VERSION) | .name')
if [ -z "$chanver" ] ; then
	>&2 echo "No Subscription Channel Matching The desired major version: ${OCP_MAJOR_VERSION}"
	>&2 echo "Requires manual intervention"
	exit 1
else
	sed -i "s/CHANNELVERSION/$chanver/" sriov-sub.yaml
	oc apply -f sriov-sub.yaml
fi
