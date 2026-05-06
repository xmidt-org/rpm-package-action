Name:           hello
Version:        0.1.0
Release:        1%{?dist}
Summary:        rpm-package-action smoke test
License:        Apache-2.0
Source0:        hello.sh
BuildArch:      noarch

%description
Trivial package used by the rpm-package-action repo to verify each
bundled distro Dockerfile builds end-to-end.

%prep

%build

%install
mkdir -p %{buildroot}%{_bindir}
install -m 0755 %{SOURCE0} %{buildroot}%{_bindir}/hello

%files
%{_bindir}/hello

%changelog
