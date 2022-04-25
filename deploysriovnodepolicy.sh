#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source ${DIR}/ocp-globals.sh
source ${DIR}/install_deps.sh

if [ "$OCP_MAJOR_VERSION" == 4.4 ]; then
  # The following only works with 4.4
  echo "to support Intel X520"
  echo "see https://tools.ietf.org/html/rfc6902#section-4.1"
  oc patch crd sriovnetworknodepolicies.sriovnetwork.openshift.io --type json -p='[{"op": "add", "path": "/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/nicSelector/properties/deviceID/enum/-","value":"154d"}]'
elif [ "$OCP_MAJOR_VERSION" == 4.5 ]; then
  # OCP 4.5 and above, need to disable the webhook
  # https://bugzilla.redhat.com/show_bug.cgi?id=1850505
  # https://github.com/openshift/sriov-network-operator/pull/204/commits/663595025b5b05ccc0ba620fe6ffd2fac8127520
  # this will be recreated, but we will have enough time to create the below policies
  oc delete ValidatingWebhookConfiguration operator-webhook-config
elif [ "$OCP_MAJOR_VERSION >= 4.6" ]; then
	# https://github.com/openshift/sriov-network-operator/blob/master/doc/quickstart.md#prerequisites
	oc patch sriovoperatorconfig default --type=merge -n openshift-sriov-network-operator --patch '{ "spec": { "enableOperatorWebhook": false } }'
else
# https://github.com/openshift/sriov-network-operator/issues/133
  cat <<'EOF' | oc apply -f -
apiVersion: v1
data:
  X520: 8086 154d 10ed
kind: ConfigMap
metadata:
  name: unsupported-nic-ids
  namespace: openshift-sriov-network-operator
EOF
sleep 40 # 30 seconds should be enough, let's make it 40
fi

echo "create network node policy for vfio-pci on enp5s0f0"
oc apply -f networkpolicy-vfiopci.yaml

echo "create network node policy for netdev on enp5s0f1"
oc apply -f networkpolicy-netdevice.yaml

sleep 300

echo "These commands need to yield a number bigger than 0 for sriov resources on the nodes"
for node in $(oc get nodes | awk '/worker/ {print $1}'); do
        oc get nodes $node -o yaml | grep openshift.io
done
