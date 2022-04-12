Guide on deploying the sriov operator and its requirements

### Step 1
Creates the Namespace, OperatorGroup and Subscription.
Also tags all workers as `feature.node.kubernetes.io/network-sriov.capable="true"`
```
bash deploysriovoperator.sh
```

### Step 2
Creates a ConfigMap to enable our old Intel cards for sriov (older versions get a workaround). Then creates two `SriovNetworkNodePolicy` for both nic cards.
```
bash deploysriovnodepolicy.sh
```

### Step 3
Optional deployment of example sriov able pods
```
bash deploysriovpod.sh
```

### Troubleshooting

#### Node Stuck in Draining Status
If the operator on a small cluster the install may stall, where the node sriov network policy will never be applied as it cannot drain the node.
Check the node annotations, when completed it should be set to `Idle`. However, in a stuck state you will have:
```
[root@openshift-jumpserver-0 ~]# oc get nodes openshift-worker-0 -o json | jq -r '.metadata.annotations."sriovnetwork.openshift.io/state"'
Draining
```

Checking why this is the case, we first identify the deamon pod for one of the stuck nodes and then check the logs:
```
[root@openshift-jumpserver-0 ~]# oc get pods -n openshift-sriov-network-operator -o wide | grep daemon
sriov-network-config-daemon-l282m         1/1     Running   0          4h54m   192.168.123.220   openshift-worker-0   <none>           <none>
sriov-network-config-daemon-zrl9t         1/1     Running   0          4h54m   192.168.123.221   openshift-worker-1   <none>           <none>
[root@openshift-jumpserver-0 ~]# oc logs sriov-network-config-daemon-l282m
(...)
E0614 21:36:52.851614 1732026 daemon.go:117] error when evicting pod "router-default-8564df6855-mj5cm" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
I0614 21:36:54.124039 1732026 daemon.go:329] nodeUpdateHandler(): node openshift-worker-1 is draining
I0614 21:36:56.109719 1732026 request.go:621] Throttling request took 1.117775327s, request: GET:https://172.30.0.1:443/api/v1/namespaces/openshift-monitoring/pods/kube-state-metrics-7bb7644f78-rsqf5
I0614 21:36:57.851862 1732026 daemon.go:117] evicting pod openshift-ingress/router-default-8564df6855-mj5cm
E0614 21:36:57.934719 1732026 daemon.go:117] error when evicting pod "router-default-8564df6855-mj5cm" (will retry after 5s): Cannot evict pod as it would violate the pod's disruption budget.
(...)
```

Here we can see that the router-default is at fault, and is managed by a ReplicaSet:
```
[root@openshift-jumpserver-0 ~]# oc get -n openshift-ingress ReplicaSet/router-default-8564df6855
NAME                        DESIRED   CURRENT   READY   AGE
router-default-8564df6855   2         2         2       19d
```

In which case it desires 2 replicas (on two different nodes) and manually changing the requirement will be overwritten by the operator.
Easiest solution is to simply delete the pod and force the upgrade through.
