all: build

build: 
	-cd components/hello && rpmbuild --define "_topdir $(PWD)/components/hello" \
	--define "_unpackaged_files_terminate_build 0" --clean \
 	-ba SPECS/hello.spec
	-tree components/hello
