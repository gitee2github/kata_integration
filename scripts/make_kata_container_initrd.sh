#!/bin/bash

# Copyright (c) Huawei Technologies Co., Ltd. 2019. All rights reserved.
# kata_integration is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: make default config
# Author: caihaomin
# Create: 2019-01-22

script_dir="$(dirname $(readlink -f $0))"
rpmlist=${script_dir}/make-initrd-rpm.list

BUILD_PATH="./build"
IMAGE_NAME=${IMAGE_NAME:-kata-containers-initrd.img}
GPU_IMAGE_NAME=${GPU_IMAGE_NAME:-kata-containers-initrd-gpu.img}
IB_IMAGE_NAME=${IB_IMAGE_NAME:-kata-containers-initrd-ib.img}
AGENT_INIT=${AGENT_INIT:-yes}
ROOTFS_DIR=${ROOTFS_DIR:-/tmp/kataAgent-rootfs}

# build kata-agent
# make agent

# create a temp dir to store rootfs
rm -rf ${ROOTFS_DIR}
mkdir -p ${ROOTFS_DIR}/lib \
	  ${ROOTFS_DIR}/lib64 \
	  ${ROOTFS_DIR}/lib/modules

mkdir -m 0755 -p ${ROOTFS_DIR}/dev \
	  ${ROOTFS_DIR}/sys \
	  ${ROOTFS_DIR}/sbin \
	  ${ROOTFS_DIR}/bin \
      ${ROOTFS_DIR}/tmp \
	  ${ROOTFS_DIR}/proc
 
if [ ! -f "${BUILD_PATH}/kata-agent" ];then
	echo "kata-agent doesn't exist!"
	exit 1
fi

# busybox
cp /sbin/busybox ${ROOTFS_DIR}/sbin/
cp ${BUILD_PATH}/kata-agent ${ROOTFS_DIR}/init
# ipvs
cp /usr/sbin/ipvsadm ${ROOTFS_DIR}/sbin
# conntrack-tools
cp /usr/sbin/conntrack ${ROOTFS_DIR}/sbin
# quota
cp /usr/bin/quota* ${ROOTFS_DIR}/bin
cp /usr/bin/quotasync ${ROOTFS_DIR}/bin
# glibc-devel glibc
cp /lib64/libnss_dns* ${ROOTFS_DIR}/lib64
cp /lib64/libnss_files* ${ROOTFS_DIR}/lib64

# cp run request files in initrd
cat $rpmlist | while read rpm
do
    if [ "${rpm:0:1}" != "#" ]; then
        rpm -ql $rpm > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            continue
        fi
        array=($(rpm -ql $rpm| grep -v "share" | grep -v ".build-id"))
        for file in ${array[@]};
        do
            source=$file
            dts_file=${ROOTFS_DIR}$file
            dts_folder=${dts_file%/*}
            if [ ! -d "$dts_folder" ];then
                mkdir -p $dts_folder
            fi
            cp -r -f -d $source $dts_folder
        done
    fi
done

#create symlinks to busybox
BUSYBOX_BINARIES=(/bin/sh /bin/mount /bin/umount /bin/ls /bin/ps /bin/file /bin/ldd /bin/tar /bin/hwclock /sbin/modprobe /sbin/depmod /bin/ip /bin/modinfo /bin/insmod /bin/rmmod)
for bin in ${BUSYBOX_BINARIES[@]}
do
 	mkdir -p ${ROOTFS_DIR}/`dirname ${bin}`
 	ln -sf /sbin/busybox ${ROOTFS_DIR}/${bin}
done

LDD_BINARIES=(/init /sbin/busybox /sbin/conntrack /sbin/ipvsadm)
for bin in ${LDD_BINARIES[@]}
 do
     ldd ${ROOTFS_DIR}${bin} | while read line
     do
 	    arr=(${line// / })

 	    for lib in ${arr[@]}
 	    do
 			echo $lib
 		    if [ "${lib:0:1}" = "/" ]; then
 			    dir=${ROOTFS_DIR}`dirname $lib`
 			    mkdir -p "${dir}"
 			    cp -f $lib $dir
 		    fi
 	    done
     done
 done

(cd ${ROOTFS_DIR} && find . | cpio -H newc -o | gzip -9 ) > ${BUILD_PATH}/${IMAGE_NAME}

if [ "${INTEGRATE_DRIVER}"x = ""x ];then
    rm -rf ${ROOTFS_DIR}
    exit 0
fi

for version in `ls /var/lib/hyper/ |grep NVIDIA-Linux-`
do
    #make kata-containers-gpu.img
    rm -f ${ROOTFS_DIR}/init
    cp ${BUILD_PATH}/kata-agent ${ROOTFS_DIR}/init
    mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-ko
    mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-so

    cp -d /var/lib/hyper/${version}/nvidia-gpu-ko/* ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-ko/
    cp -d /var/lib/hyper/${version}/nvidia-gpu-so/* ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-so/
    cp /var/lib/hyper/${version}/nvidia-gpu-so/libnvidia-ml.so* ${ROOTFS_DIR}/lib64
    ldconfig -n ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-so

    # tensorflow has some wired logic to detect file names like "libcuda.so".
    pushd ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-so

    for f in `ls *so.0`; do ln -s $f ${f%.0}; done
    for f in `ls *so.1`; do ln -s $f ${f%.1}; done
    for f in `ls *so.2`; do ln -s $f ${f%.2}; done
    popd
    ( cd ${ROOTFS_DIR} && find . | cpio -H newc -o | gzip -9 ) > ${BUILD_PATH}/kata-containers-initrd-gpu-${version##*-}.img
	#make kata-containers-gpu.img end

	#make kata-containers-gpu-ib.img
	mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko
	mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so
	cp -d /var/lib/hyper/infiniband-ko/* ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko/
	cp -d /var/lib/hyper/infiniband-so/* ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so/
	ldconfig -n ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so

	( cd ${ROOTFS_DIR} && find . | cpio -H newc -o | gzip -9 ) > ${BUILD_PATH}/kata-containers-initrd-gpu-${version##*-}-ib.img
	#make kata-containers-gpu-ib.img end

    #clear the gpu files
    rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-ko
    rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/nvidia-gpu-so
    rm -rf ${ROOTFS_DIR}/lib64/libnvidia-ml.so*
	#end of clear gpu files

	#clear the infiniband files
	rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko/
	rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so/
	#end of clear infiniband files
done

#make kata-containers-ib.img
if [ -d /var/lib/hyper/infiniband-ko/ ] && [ -d /var/lib/hyper/infiniband-so ];then
	mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko
	mkdir -p ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so
	cp -d /var/lib/hyper/infiniband-ko/* ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko/
	cp -d /var/lib/hyper/infiniband-so/* ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so/
	ldconfig -n ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so

	rm -f ${ROOTFS_DIR}/init
	cp ${BUILD_PATH}/kata-agent ${ROOTFS_DIR}/init

	( cd ${ROOTFS_DIR} && find . | cpio -H newc -o | gzip -9 ) > ${BUILD_PATH}/kata-containers-initrd-ib.img
	#make kata-containers-ib.img end

	#clear the infiniband files
	rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-ko/
	rm -rf ${ROOTFS_DIR}/var/lib/kata/drivers/infiniband-so/
	#end of clear infiniband files
fi

rm -rf ${ROOTFS_DIR}
