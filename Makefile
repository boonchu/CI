all: build verify

build: 
	-cd components/hello && rpmbuild --define "_topdir $(PWD)/components/hello" \
	--define "_unpackaged_files_terminate_build 0" --clean \
 	-ba SPECS/hello.spec
	-tree components/hello

verify:
	-cd components/hello && rpmlint SPECS/hello.spec SRPMS/hello* RPMS/*/hello*
