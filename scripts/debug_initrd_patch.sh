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
# Description: debug initrd patch
# Author: caihaomin
# Create: 2019-01-22

# This file should work under kata_integration dir
# add/rm debug vm patch to agent

if [ $# != 1 ]; then
    echo "usage: sh debug_initrd_patch.sh patch/unpatch"
    exit 1
fi
cmd=$1

currentDir=`pwd`
cd ${currentDir}/agent/
if [ ${cmd} == "patch" ];then
    echo "add debug rootfs patch to agent"
    patch -p1 < ${currentDir}/patch/debug_vm.patch
elif [ ${cmd} == "unpatch" ]; then
    echo "delete debug rootfs patch from agent"
    patch -Rp1 < ${currentDir}/patch/debug_vm.patch
fi

cd ${currentDir}

