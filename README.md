# CI
#### Continueous Integration Process
* rpmbuild tools, jenkins, artifactory

##### Start with component rpm build
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
* This is simulation action that engineer might think about why we do not go for automation process? 
  - what happens tomorrow if Unix engineer plan to release bug fix edition for nginx for production?
  - any tool can help engineer to craft automation way to release bug fix?
  - jenkins is the one of automation tool that engineer can deploy job, run unit testing, etc.

##### Building rpm with [mock](http://fedoraproject.org/wiki/Projects/Mock)
* [mock manual](http://linux.die.net/man/1/mock)
* Use EPEL fedora with RHEL 7
```
$ sudo yum-config-manager --enable --add-repo=http://dl.fedoraproject.org/pub/epel/7/x86_64
$ sudo yum install mock
```
* run default to build with mock and investigate from temp folder.
```
$ rpmbuild --define "_topdir $HOME/CI/components/hello" \
--define "_unpackaged_files_terminate_build 0" \
--clean -bs SPECS/hello.spec --nodeps

$ sudo mock --define "_unpackaged_files_terminate_build 0" \
--resultdir=/tmp/hello rebuild \
SRPMS/hello-2.8-1.src.rpm

$ tree /tmp/hello
/tmp/hello
├── build.log
├── hello-2.8-1.src.rpm
├── hello-debuginfo-2.8-1.x86_64.rpm
├── root.log
└── state.log
```
* mock is super cool. just download the soruce rpm and build and test it. 
* can instruct mock to build based on other OS version.

##### Start with jenkins
![jenkins](https://github.com/boonchu/CI/blob/master/components/jenkins.png)
* Suggestions:
  - Jenkins requires very good performance of hardware to run jobs on executors. It depends on demands of your user environments in your company. 
* install git plugins (Manage Jenkins -> Manage Plugins)
* after running new job, here you go!
![jenkins-rpm-jobs](https://github.com/boonchu/CI/blob/master/components/jenkins-rpm-jobs.png)
* think about the plan how to revision new package, test them before promoting to artifactory.
* adding executor capacity for rpm rhel 7 build and test
  - plan out and procure with good hardware
  - of course, you need to kickstart new nodes
  - update ssh keys between master jenkins to executors
  - defines the workspace for jobs
![jenkins-executors](https://github.com/boonchu/CI/blob/master/components/jenkins-executors.png)

##### Start with artifactory repository
* install JDK 7
* [download open source version](https://bintray.com/jfrog/artifactory-rpms/artifactory/view) from artifactory site and install it. 
```
$ sudo systemctl start artifactory 
$ sudo systemctl enable artifactory
$ sudo systemctl status artifactory -l
$ sudo /opt/jfrog/artifactory/bin/artifactoryctl check
Artifactory is running, on pid=7704
$ tail -f /var/opt/jfrog/artifactory/logs/artifactory.log
2015-02-11 14:00:07,481 [art-init] [INFO ] (o.a.s.ArtifactoryApplicationContext:222) - Initializing org.artifactory.repo.cleanup.InternalArtifactCleanupService
2015-02-11 14:00:07,489 [art-init] [INFO ] (o.a.s.ArtifactoryApplicationContext:222) - Initializing org.artifactory.storage.InternalStorageService
2015-02-11 14:00:07,491 [art-init] [INFO ] (o.a.c.ConvertersManagerImpl:113) - Updating local file data/artifactory.properties to running version
2015-02-11 14:00:07,553 [art-init] [INFO ] (o.a.s.ArtifactoryApplicationContext:361) - Artifactory application context is ready.
2015-02-11 14:00:07,553 [art-init] [INFO ] (o.a.c.ConvertersManagerImpl:148) - Sending configuration update message to slaves
2015-02-11 14:00:07,555 [art-init] [INFO ] (o.a.w.s.ArtifactoryContextConfigListener:225) -
###########################################################
### Artifactory successfully started (18.060 seconds)   ###
###########################################################
```
* access from web service http://localhost:8081/ (login:admin, pass:password)
* update: free trail version is not quite usable. Many good add on features are off such as YUM, docker, PyPI, LDAP. :-(
* Okie. Alternatively, JFrog offers the open source platform for YUM repository. So, I pushed hello world package to the platform and register with yum config manager. (see example: [sbt](https://bintray.com/sbt/rpm/sbt/view))
* this is my open source repository from bintray.com, [link](https://bintray.com/boonchu/yum-remote-repo)
* May be... you can try [30 days free trail version with registration](https://www.jfrog.com/artifactory/free-trial/)
```
$ cd /etc/yum.repos.d/ && sudo wget https://bintray.com/boonchu/yum-remote-repo/rpm -O bintray-boonchu-yum-remote-repo.repo 
$ sudo yum search hello
```
