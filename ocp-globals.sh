#!/usr/bin/env bash

OCP_MAJOR_VERSION=$(oc get clusterversion -o json | jq -r '.items[0].status.desired.version | split(".") | "\(.[0]).\(.[1])"')
STORAGE_CLASS=$(oc get storageclass | awk '/default/ {print $1}')
