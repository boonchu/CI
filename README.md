# CI
Continueous Integration Process

##### Start with component build process
* Use [hello world rpm as the example](https://fedoraproject.org/wiki/How_to_create_a_GNU_Hello_RPM_package)

* install rpmdevtools and setup rpm folders
```
sudo yum install rpmdevtools
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


