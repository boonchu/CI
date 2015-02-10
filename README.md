# CI
Continueous Integration Process

##### Start with component build process
* Use [hello world rpm as the example](https://fedoraproject.org/wiki/How_to_create_a_GNU_Hello_RPM_package)

* install rpmdevtools and setup rpm folders
```
sudo yum install rpmdevtools
rpmdev-setuptree
cd rpmbuild/SOURCES && wget wget http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz
cd rpmbuild/SPECS && rpmdev-newspec hello
```
* edit hello.spec in SPECS folder
```
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

