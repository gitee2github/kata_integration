%global debug_package %{nil}
%define VERSION v1.0.0
%define RELEASE 1

Name:           kata-integration
Version:        %{VERSION}
Release:        %{RELEASE}
Summary:        Kata Container integration
License:        Apache 2.0
URL:            https://gitee.com/src-openeuler/kata_integration
Source0:        %{name}-%{version}.tar.gz

BuildRoot:      %_topdir/BUILDROOT
BuildRequires: automake gcc glibc-devel glibc-static patch 

%description
This is a usefult tool for building Kata Container components.

%prep
%setup -q -c -a 0 -n %{name}-%{version}

%build

%clean

%files

%doc

%changelog
* Wed Aug 26 2020 jiangpengf<jiangpengfei9@huawei.com> - 1.0.0-1
- Type:enhancement
- ID:NA
- SUG:NA
- DESC:add initial kata-integration.spec
