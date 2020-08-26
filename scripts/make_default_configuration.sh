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

KATA_RUNTIME_PATH=$(readlink -f $1)
KATA_CONFIG_PATH=$KATA_RUNTIME_PATH/cli/config/configuration-qemu.toml
ARCH=`arch`

sed -i 's/qemu-lite-system-x86_64/qemu-kvm/' $KATA_CONFIG_PATH
sed -i 's#/usr/share/kata-containers/vmlinuz\.container#/var/lib/kata/kernel#' $KATA_CONFIG_PATH
sed -i 's#/usr/share/kata-containers/kata-containers-initrd\.img#/var/lib/kata/kata-containers-initrd\.img#' $KATA_CONFIG_PATH
sed -i 's/^image/#image/' $KATA_CONFIG_PATH
sed -i 's/^#default_memory = /default_memory = /' $KATA_CONFIG_PATH
sed -i 's#block_device_driver = \"virtio-scsi\"#block_device_driver = \"virtio-blk\"#' $KATA_CONFIG_PATH
sed -i 's/^#enable_blk_mount/enable_blk_mount/' $KATA_CONFIG_PATH
sed -i 's#/usr/libexec/kata-containers/kata-proxy#/usr/bin/kata-proxy#' $KATA_CONFIG_PATH
sed -i 's#/usr/libexec/kata-containers/kata-shim#/usr/bin/kata-shim#' $KATA_CONFIG_PATH
sed -i 's#/usr/libexec/kata-containers/kata-netmon#/usr/bin/kata-netmon#' $KATA_CONFIG_PATH
sed -i 's/^#enable_netmon/enable_netmon/' $KATA_CONFIG_PATH
sed -i 's/^#disable_new_netns/disable_new_netns/' $KATA_CONFIG_PATH
sed -i 's/^#disable_vhost_net/disable_vhost_net/' $KATA_CONFIG_PATH
sed -i 's/^#block_device_cache_set/block_device_cache_set/' $KATA_CONFIG_PATH
sed -i 's/^#block_device_cache_direct/block_device_cache_direct/' $KATA_CONFIG_PATH
sed -i 's#path = \"/usr/bin/qemu-.*\"#path = \"/usr/bin/qemu-kvm\"#' $KATA_CONFIG_PATH
sed -i 's/^internetworking_model.*$/internetworking_model=\"bridged\"/' $KATA_CONFIG_PATH

if [ "$ARCH" == "aarch64" ];then
    sed -i 's/^machine_type.*$/machine_type = \"virt\"/' $KATA_CONFIG_PATH
    sed -i 's/^block_device_driver.*$/block_device_driver = \"virtio-scsi\"/' $KATA_CONFIG_PATH
    sed -i 's/^kernel_params.*$/kernel_params = \"agent.log=debug pcie_ports=native pci=pcie_bus_perf\"/' $KATA_CONFIG_PATH
    sed -i 's/^hypervisor_params.*$/hypervisor_params = \"kvm-pit.lost_tick_policy=discard pcie-root-port.fast-plug=1 pcie-root-port.x-speed=16 pcie-root-port.x-width=32 pcie-root-port.fast-unplug=1\"/' $KATA_CONFIG_PATH
else
    sed -i 's/^kernel_params.*$/kernel_params = \"agent.log=debug\"/' $KATA_CONFIG_PATH
    sed -i 's/^#hotplug_vfio_on_root_bus/hotplug_vfio_on_root_bus/' $KATA_CONFIG_PATH
fi

# debug options
sed -i 's/^#enable_debug.*$/enable_debug = true/' $KATA_CONFIG_PATH
