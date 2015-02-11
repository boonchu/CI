# CI
Continueous Integration Process

##### Start with component build process
* Use [hello world rpm as the example](https://fedoraproject.org/wiki/How_to_create_a_GNU_Hello_RPM_package)

* install rpmdevtools and setup rpm folders
```
sudo yum install rpmdevtools rpmlint
rpmdev-setuptree
rsync -av ~/rpmbuild/* ~/CI/components/hello
cd ~/CI/components
cd hello/SOURCES && wget http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz
cd ~/CI/components
cd hello/SPECS && rpmdev-newspec hello
```
* edit hello.spec in SPECS folder
```
$ vim ~/CI/components/hello/SPECS/hello.spec
Name:     hello
Version:  2.8
Release:  1
Summary:  The "Hello World" program from GNU
License:  GPLv3+
URL:      http://ftp.gnu.org/gnu/hello    
Source0:  http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz

%description
The "Hello World" program, done with all bells and whistles of a proper FOSS 
project, including configuration, build, internationalization, help files, etc.

%changelog
* Thu Jul 07 2011 The Coon of Ty <Ty@coon.org> - 2.8-1
- Initial version of the package
```
* per discussion, I prefer custom rpmbuild home folder. This is how to [setup](http://stackoverflow.com/questions/416983/why-is-topdir-set-to-its-default-value-when-rpmbuild-called-from-tcl)
```
$ cd ~/CI/components/hello
$ rpmbuild --define "_topdir $HOME/CI/components/hello" -ba SPECS/hello.spec
Checking for unpackaged file(s): /usr/lib/rpm/check-files /home/bigchoo/CI/components/hello/BUILDROOT/hello-2.8-1.x86_64
Wrote: /home/bigchoo/CI/components/hello/SRPMS/hello-2.8-1.src.rpm
Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.yZsvBe
+ umask 022
+ cd /home/bigchoo/CI/components/hello/BUILD
+ /usr/bin/rm -rf /home/bigchoo/CI/components/hello/BUILDROOT/hello-2.8-1.x86_64
+ exit 0llo.spec
```
* output example of directory structure
```
bigchoo@vmk1 1243 $ tree
.
├── BUILD
├── BUILDROOT
├── RPMS
├── SOURCES
│   └── hello-2.8.tar.gz
├── SPECS
│   └── hello.spec
└── SRPMS
    └── hello-2.8-1.src.rpm

6 directories, 3 files
```
* explore into next level to do this
  - need to declare  the %files section. 
  - Do not hardcode names like /usr/bin/, but use macros, like %{_bindir}/hello instead. 
  - declared manual pages in the %doc subsection: %doc %{_mandir}/man1/hello.1.gz.
  - delete the 'dir' file in %install: rm -f %{buildroot}/%{_infodir}/dir
  - requires(post): info and Requires(preun): info

```
%prep
%autosetup

%build
%configure
make %{?_smp_mflags}

%install
%make_install
%find_lang %{name}
rm -f %{buildroot}/%{_infodir}/dir

%post
/sbin/install-info %{_infodir}/%{name}.info %{_infodir}/dir || :

%preun
if [ $1 = 0 ] ; then
/sbin/install-info --delete %{_infodir}/%{name}.info %{_infodir}/dir || :
fi

%file -f %{name}.lang
%doc AUTHORS ChangeLog COPYING NEWS README THANKS TODO
%{_mandir}/man1/hello.1.gz
%{_infodir}/%{name}.info.gz
%{_bindir}/hello
```
* run rpmbuild and explore what we have in file tree
  - part of macro in rpm 4.x, you need to turn off feature to avoid problem during the build process [ turn off the Fascist build polic](http://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/RPM_Guide/ch09s05s07.html)
```
$ sudo yum install gcc (dependency package by hello rpmbuild)
$ rpmbuild --define "_topdir $HOME/CI/components/hello" \
 --define "_unpackaged_files_terminate_build 0" \
 --clean \
 -ba SPECS/hello.spec
```
* use rpmlint to inspect the output. (should be bare minimum set of warnings)
```
bigchoo@vmk1 1331 $ rpmlint SPECS/hello.spec SRPMS/hello* RPMS/*/hello*
hello-debuginfo.x86_64: W: only-non-binary-in-usr-lib
2 packages and 1 specfiles checked; 0 errors, 1 warnings.

bigchoo@vmk1 1359 $ tree
.
├── BUILD
├── BUILDROOT
├── RPMS
│   └── x86_64
│       └── hello-debuginfo-2.8-1.x86_64.rpm
├── SOURCES
│   └── hello-2.8.tar.gz
├── SPECS
│   └── hello.spec
└── SRPMS
    └── hello-2.8-1.src.rpm

7 directories, 4 files
```