#!/bin/bash
mkdir -p /ko_output
BUILD_VERSION=$(cat LKM/src/init.c | grep MODULE_VERSION | awk -F '"' '{print $2}')
KO_NAME=$(grep "MODULE_NAME" ./LKM/Makefile | grep -m 1 ":=" | awk '{print $3}')

for each_lt_version in `ls /root/headers/kernel-plus* | grep kernel-plus-devel | sed 's|/root/headers/kernel-plus-devel-\(.*\).centos.plus.x86_64.rpm|\1|g'`
do 
    yum remove -y kernel-devel kernel-plus-devel &> /dev/null
    yum remove -y kernel-tools kernel-plus-tools &> /dev/null
    yum remove -y kernel-tools-libs kernel-plus-tools-libs &> /dev/null

    rpm -i --force /root/headers/{kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm,kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm,kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm}
    rm -f /root/headers/{kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm,kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm,kernel-plus-devel-$each_lt_version.centos.plus.x86_64.rpm}
    KV=$each_lt_version.centos.plus.x86_64
    KVERSION=$KV make -C ./LKM clean || true 

    BATCH=true KVERSION=$KV make -C ./LKM -j all | tee /ko_output/${KO_NAME}_${BUILD_VERSION}_${KV}_amd64.log || true 
    sha256sum  ./LKM/${KO_NAME}.ko | awk '{print $1}' > /ko_output/${KO_NAME}_${BUILD_VERSION}_${KV}_amd64.sign  || true  

    if [ -s /ko_output/${KO_NAME}_${BUILD_VERSION}_${KV}_amd64.sign ]; then
        # The file is not-empty.
        echo ok > /dev/null
    else
        # The file is empty.
        rm -f /ko_output/${KO_NAME}_${BUILD_VERSION}_${KV}_amd64.sign
    fi
    mv ./LKM/${KO_NAME}.ko /ko_output/${KO_NAME}_${BUILD_VERSION}_${KV}_amd64.ko || true 
    
    KVERSION=$KV  make -C ./LKM clean || true
done

