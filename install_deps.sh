#!/bin/bash

install_bc() {
        which bc > /dev/null
        if [ "$?" != "0" ]; then
                yum install bc -y
        fi
}

install_bc

