#needsrootforbuild
%global debug_package %{nil}
%global kernel_version 4.19.36
%if "%{!?VERSION:1}"
%define VERSION v1.7.0
%endif

%if "%{!?RELEASE:1}"
%define RELEASE 21
%endif

%define __debug_install_post   \
   %{_rpmconfigdir}/find-debuginfo.sh %{?_find_debuginfo_opts} "%{_builddir}/%{?buildsubdir}"\
%{nil}

Name:           kata-containers
Version:        %{VERSION}
Release:        %{RELEASE}
Summary:        Kata Container integration
License:        Apache 2.0
URL:            https://gitee.com/src-openeuler/kata_integration
Source0:        %{name}-%{version}.tar.gz
Source1:        kata-runtime-%{version}.tar.gz
Source2:        kata-agent-%{version}.tar.gz
Source3:        kata-proxy-%{version}.tar.gz
Source4:        kata-shim-%{version}.tar.gz
Source5:        linux-%{kernel_version}.tar.gz

BuildRoot:      %_topdir/BUILDROOT
BuildRequires:  automake golang gcc bc glibc-devel glibc-static busybox glib2-devel glib2 ipvsadm conntrack-tools nfs-utils
BuildRequires:  patch elfutils-libelf-devel openssl-devel bison flex

%description
This is core component of Kata Container, to make it work, you need a docker engine.

%prep
%setup -q -c -a 0 -n %{name}-%{version}
%setup -q -c -a 1 -n %{name}-%{version}/runtime
%setup -q -c -a 2 -n %{name}-%{version}/agent
%setup -q -c -a 3 -n %{name}-%{version}/proxy
%setup -q -c -a 4 -n %{name}-%{version}/shim
%setup -q -c -a 5 -n kernel

cd %{_builddir}/kernel
mv kernel linux
if ls patches.tar.* >/dev/null 2>&1;then
    tar -xf patches.tar.*
fi
cd %{_builddir}/kernel/linux/
%ifarch %{ix86} x86_64
cp %{_builddir}/%{name}-%{version}/hack/config-kata-x86_64 ./.config
%else
cp %{_builddir}/%{name}-%{version}/hack/config-kata-arm64 ./.config
%endif

patch_list="%{_builddir}/kernel/series.conf"
IFS=$'\n'
for patch_name in `cat $patch_list`
do
        echo $patch_name
	if  [ "${patch_name:0:1}"  != "#" ]; then
                patch -p1 -F1 -s < %{_builddir}/kernel/${patch_name}
                echo "add patch done : $patch_name"
        fi
done

%build
cd %{_builddir}/kernel/linux/
make %{?_smp_mflags}

cd %{_builddir}/%{name}-%{version}
mkdir -p -m 750 build
make runtime
make proxy
make shim
%if 0%{?integrate_driver}
    make initrd INTEGRATE_DRIVER=true
%else
    make initrd
%endif

%install
mkdir -p -m 755  %{buildroot}/var/lib/kata
%ifarch %{ix86} x86_64
install -p -m 755 -D %{_builddir}/kernel/linux/arch/x86_64/boot/bzImage %{buildroot}/var/lib/kata/kernel
%else
install -p -m 755 -D %{_builddir}/kernel/linux/arch/arm64/boot/Image %{buildroot}/var/lib/kata/kernel
%endif

cd %{_builddir}/%{name}-%{version}
mkdir -p -m 750  %{buildroot}/usr/bin
install -p -m 750 ./build/kata-runtime ./build/kata-proxy ./build/kata-shim ./build/kata-netmon %{buildroot}/usr/bin/
install -p -m 640 ./build/kata-containers-initrd.img %{buildroot}/var/lib/kata/
mkdir -p -m 750 %{buildroot}/usr/share/defaults/kata-containers/
install -p -m 640 -D ./runtime/cli/config/configuration-qemu.toml %{buildroot}/usr/share/defaults/kata-containers/configuration.toml

%clean

%files
/usr/bin/kata-runtime
/usr/bin/kata-proxy
/usr/bin/kata-shim
/usr/bin/kata-netmon
/var/lib/kata/kernel
/var/lib/kata/kata-containers-initrd.img
/usr/share/defaults/kata-containers/configuration.toml

%doc


%changelog
* Tue Apr 21 2020 jiangpengf<jiangpengfei9@huawei.com> - 1.0.3.21
- Type:bugfix
- ID:NA
- SUG:NA
- DESC:fix kata-netmon ignore add RTPROT_KERNEL route problem

* Thu Apr 2 2020 jiangpengf<jiangpengfei9@huawei.com> - 1.0.3.20
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:add netmon back to rpm package and enable default hypervisor_params

* Tue Dec 31 2019 yangfeiyu<yangfeiyu2@huawei.com> - 1.0.3.18
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:Do not use fPIC in making kernel.

* Fri Nov 29 2019 yangfeiyu<yangfeiyu2@huawei.com> - 1.0.3.17
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:Build kernel in kata-container.

* Wed Aug 14 2019 leizhongkai<leizhongkai@huawei.com> - next-1.0.3.h16
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:Use definition to control whether to integrate drivers.

* Mon Jan 31 2019 jiangpengfei<jiangpengfei9@huawei.com> - next-1.0.3.h6
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:fix kata-runtime to satisfy docker 18.09

* Mon Jan 7 2019 jiangpengfei<jiangpengfei9@huawei.com> - next-1.0.3.h5
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:update kata-container spec 

* Fri Dec 28 2018 jiangpengfei<jiangpengfei9@huawei.com> - next-1.0.3.h4
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:update kata-container spec 

* Fri Nov 20 2018 jiangpengfei<jiangpengfei9@huawei.com> - next-1.0.3.h3
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:update kata-container spec 

* Fri Oct 19 2018 leizhongkai<leizhongkai@huawei.com> - next-1.0.3.h1
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:init kata-container spec 
