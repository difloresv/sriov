#/bin/bash -x

echo "create new sriov-testing project"
oc new-project sriov-testing
oc project sriov-testing

echo "create network enp5s0f0 vfio-pci"
cat <<'EOF'>sriovnetwork-enp5s0f0.yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-net-enp5s0f0-vfiopci
  namespace: openshift-sriov-network-operator
spec:
  networkNamespace: sriov-testing
  ipam: '{ "type": "static" }'
  vlan: 209
  resourceName: enp5s0f0Vfiopci
  trust: "on"
  capabilities: '{ "mac": true, "ips": true }'
EOF
oc apply -f sriovnetwork-enp5s0f0.yaml

echo "create network enp5s0f1 netdevice"
cat <<'EOF'>sriovnetwork-enp5s0f1.yaml
apiVersion: sriovnetwork.openshift.io/v1
kind: SriovNetwork
metadata:
  name: sriov-net-enp5s0f1-netdev
  namespace: openshift-sriov-network-operator
spec:
  networkNamespace: sriov-testing
  ipam: '{ "type": "static" }'
  vlan: 209
  resourceName: enp5s0f1Netdev
  trust: "on"
  capabilities: '{ "ips": true }'
EOF
oc apply -f sriovnetwork-enp5s0f1.yaml

echo "create vfio-pci pods"
cat <<'EOF'>sriovpoda.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sriovpoda
  namespace: sriov-testing
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
	{
		"name": "sriov-net-enp5s0f0-vfiopci",
		"ips": ["192.168.10.10/24", "2001::10/64"]
	}
]'
spec:
  containers:
  - name: sample-container
    image: centos:8
    imagePullPolicy: IfNotPresent
    command: ["sleep", "infinity"]
EOF
oc apply -f sriovpoda.yaml

cat <<'EOF'>sriovpodb.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sriovpodb
  namespace: sriov-testing
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
        {
                "name": "sriov-net-enp5s0f0-vfiopci",
                "ips": ["192.168.10.11/24", "2001::11/64"]
        }
]'
spec:
  containers:
  - name: sample-container
    image: centos:8
    imagePullPolicy: IfNotPresent
    command: ["sleep", "infinity"]
EOF
oc apply -f sriovpodb.yaml

echo "create netdev pods"
cat <<'EOF'>sriovpodc.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sriovpodc
  namespace: sriov-testing
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
        {
                "name": "sriov-net-enp5s0f1-netdev",
                "ips": ["192.168.10.12/24", "2001::12/64"]
        }
]'
spec:
  containers:
  - name: sample-container
    image: centos:8
    imagePullPolicy: IfNotPresent
    command: ["sleep", "infinity"]
EOF
oc apply -f sriovpodc.yaml

cat <<'EOF'>sriovpodd.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sriovpodd
  namespace: sriov-testing
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
        {
                "name": "sriov-net-enp5s0f1-netdev",
                "ips": ["192.168.10.13/24", "2001::13/64"]
        }
]'
spec:
  containers:
  - name: sample-container
    image: centos:8
    imagePullPolicy: IfNotPresent
    command: ["sleep", "infinity"]
EOF
oc apply -f sriovpodd.yaml
