# docker_image_diff

Compares the list of installed RPM packages between two Docker images from
the local Docker registry.
Usage:

	$ ./docker_image_diff.sh <DOCKER_OLD_IMG> <DOCKER_NEW_IMG>

Prints UPDATED, ADDED and REMOVED packages in `<DOCKER_NEW_IMG>` compared to `<DOCKER_OLD_IMG>`.

Example:

	# ./docker_image_diff.sh fedora:23 fedora:24
	Diff between fedora:23 and fedora:24


	UPDATED packages in fedora:24:
	============================================================
	SRPM acl-2.2.52-11.fc24: acl-2.2.52-11.fc24 libacl-2.2.52-11.fc24 
	SRPM attr-2.4.47-16.fc24: libattr-2.4.47-16.fc24 
	SRPM audit-2.5.2-1.fc24: audit-libs-2.5.2-1.fc24 
	SRPM basesystem-11-2.fc24: basesystem-11-2.fc24 
	SRPM bash-4.3.42-5.fc24: bash-4.3.42-5.fc24 
	SRPM bzip2-1.0.6-20.fc24: bzip2-libs-1.0.6-20.fc24 
	SRPM ca-certificates-2016.2.7-1.0.fc24: ca-certificates-2016.2.7-1.0.fc24 
	SRPM chkconfig-1.7-2.fc24: chkconfig-1.7-2.fc24 
	SRPM coreutils-8.25-5.fc24: coreutils-8.25-5.fc24 
	SRPM cracklib-2.9.6-2.fc24: cracklib-2.9.6-2.fc24 cracklib-dicts-2.9.6-2.fc24 
	SRPM crypto-policies-20151104-2.gitf1cba5f.fc24: crypto-policies-20151104-2.gitf1cba5f.fc24 
	SRPM cryptsetup-1.7.1-1.fc24: cryptsetup-libs-1.7.1-1.fc24 
	SRPM curl-7.47.1-4.fc24: curl-7.47.1-4.fc24 libcurl-7.47.1-4.fc24 
	SRPM cyrus-sasl-2.1.26-26.2.fc24: cyrus-sasl-lib-2.1.26-26.2.fc24 
	SRPM dbus-1.11.2-1.fc24: dbus-1.11.2-1.fc24 dbus-libs-1.11.2-1.fc24 
	SRPM deltarpm-3.6-15.fc24: deltarpm-3.6-15.fc24 
	SRPM diffutils-3.3-13.fc24: diffutils-3.3-13.fc24 
	SRPM dnf-1.1.9-2.fc24: dnf-1.1.9-2.fc24 dnf-conf-1.1.9-2.fc24 dnf-yum-1.1.9-2.fc24 python3-dnf-1.1.9-2.fc24 
	...

	ADDED packages in fedora:24:
	============================================================
	SRPM bash-completion-2.3-1.fc24: bash-completion-2.3-1.fc24 
	SRPM coreutils-8.25-5.fc24: coreutils-common-8.25-5.fc24 
	SRPM glibc-2.23.1-7.fc24: glibc-all-langpacks-2.23.1-7.fc24 
	SRPM libpsl-0.13.0-1.fc24: libpsl-0.13.0-1.fc24 
	SRPM libsecret-0.18.5-1.fc24: libsecret-0.18.5-1.fc24 
	SRPM libunistring-0.9.4-3.fc24: libunistring-0.9.4-3.fc24 
	SRPM lz4-r131-2.fc24: lz4-r131-2.fc24 
	SRPM pkgconfig-0.29-2.fc24: pkgconfig-0.29-2.fc24 
	SRPM python3-3.5.1-7.fc24: system-python-libs-3.5.1-7.fc24 

	REMOVED packages in fedora:24:
	============================================================
	libuser-0.62-1.fc23
