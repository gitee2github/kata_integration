# Copyright (c) Huawei Technologies Co., Ltd. 2019. All rights reserved.
# kata_integration is licensed under the Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#     http://license.coscl.org.cn/MulanPSL2
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT, MERCHANTABILITY OR FIT FOR A PARTICULAR
# PURPOSE.
# See the Mulan PSL v2 for more details.
# Description: Makefile of kata_integration
# Author: caihaomin
# Create: 2019-01-22

.NOTPARALLEL:

RUNTIME_PATH = ./runtime
PROXY_PATH = ./proxy
SHIM_PATH = ./shim
KATA_AGENT_PATH = ./agent
BUILD_PATH = ./build
AGENT_INIT = yes

all: 

.PHONY: all kernel patch-kernel runtime proxy shim agent busybox initrd install clean


runtime: agent
	cd runtime; sh apply-patches
	cp -f $(KATA_AGENT_PATH)/protocols/grpc/*.pb.go $(RUNTIME_PATH)/vendor/github.com/kata-containers/agent/protocols/grpc/
	cp -f $(KATA_AGENT_PATH)/pkg/types/types.pb.go $(RUNTIME_PATH)/vendor/github.com/kata-containers/agent/pkg/types/
	cp -f $(KATA_AGENT_PATH)/protocols/grpc/utils.go $(RUNTIME_PATH)/vendor/github.com/kata-containers/agent/protocols/grpc/
	cp -f $(KATA_AGENT_PATH)/protocols/grpc/version.go $(RUNTIME_PATH)/vendor/github.com/kata-containers/agent/protocols/grpc/
	sh ./scripts/build_kata_runtime.sh $(RUNTIME_PATH)
	sh ./scripts/make_default_configuration.sh $(RUNTIME_PATH)
	cp -f $(RUNTIME_PATH)/kata-runtime $(BUILD_PATH)/
	cp -f $(RUNTIME_PATH)/kata-netmon $(BUILD_PATH)/

proxy:
	cd proxy; sh apply-patches
	sh ./scripts/build_kata_proxy.sh $(PROXY_PATH)
	cp -f $(PROXY_PATH)/kata-proxy $(BUILD_PATH)/
	
shim:
	cd shim; sh apply-patches
	sh ./scripts/build_kata_shim.sh $(SHIM_PATH)
	cp -f $(SHIM_PATH)/kata-shim $(BUILD_PATH)/


agent:
	cd agent; sh apply-patches
	sh ./scripts/build_kata_agent.sh $(KATA_AGENT_PATH)
	cp -f $(KATA_AGENT_PATH)/kata-agent $(BUILD_PATH)/

test: 
	docker run -ti --rm --runtime=kata-runtime  busybox sh

initrd: agent
	sh ./scripts/make_kata_container_initrd.sh

debug-initrd: runtime
	sh ./scripts/enable_debug_configuration.sh $(RUNTIME_PATH)
	sh ./scripts/debug_initrd_patch.sh patch
	make agent
	sh ./scripts/debug_initrd_patch.sh unpatch
	sh ./scripts/make_kata_container_initrd.sh

install:
	install -p -m 750 $(BUILD_PATH)/kata-runtime /usr/bin/
	install -p -m 750 $(BUILD_PATH)/kata-proxy /usr/bin/
	install -p -m 750 $(BUILD_PATH)/kata-shim /usr/bin/
	install -p -m 640 -D $(RUNTIME_PATH)/cli/config/configuration-qemu.toml usr/share/defaults/kata-containers/configuration.toml

clean:
	rm -f $(BUILD_PATH)/kata-containers-kernel
	rm -f $(BUILD_PATH)/kata-containers-initrd.img
	rm -f $(BUILD_PATH)/kata-containers-inird-gpu.img
	rm -f $(BUILD_PATH)/busybox
	rm -f $(BUILD_PATH)/kata-runtime
	rm -f $(BUILD_PATH)/kata-agent
