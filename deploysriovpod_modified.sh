#/bin/bash -x

echo "create new sriov-testing project"
oc new-project sriov-testing
oc project sriov-testing

echo "create network enp5s0f0 vfio-pci"
oc apply -f sriovnetwork-enp5s0f0.yaml

echo "create network enp5s0f1 netdevice"
oc apply -f sriovnetwork-enp5s0f1.yaml

echo "create vfio-pci pods"
oc apply -f sriovpoda_modified.yaml

oc apply -f sriovpodb.yaml

echo "create netdev pods"
oc apply -f sriovpodc.yaml

oc apply -f sriovpodd.yaml
