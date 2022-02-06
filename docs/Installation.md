# Installation

This chapter explains how to build and install Porion Build Manager.

## Before Building

To build the Porion Build Manager you will need the GNAT Ada compiler, either
the FSF version available in Debian, FreeBSD or NetBSD systems or the
AdaCore GNAT Community 2021 edition.

### Ubuntu

Install the following packages:
```
sudo apt-get install -y make gnat gprbuild git libsqlite3-dev
```

### FreeBSD 12

Install the following packages:

```
pkg install gmake gcc6-aux-20180516_1,1 gprbuild-20160609_1 git gnupg-2.3.1 sqlite3-3.35.5_3
```

## Getting the sources

The project uses a sub-module to help you in the integration and build
process.  You should checkout the project with the following commands:

```
git clone --recursive https://gitlab.com/stcarrez/porion.git
cd porion
```

## Configuration

The library uses the `configure` script to detect the build environment.
If some component is missing, the
`configure` script will report an error or it will disable the feature.
The `configure` script provides several standard options
and you may use:

  * `--prefix=DIR` to control the installation directory,
  * `--disable-nls` to disable NLS support,
  * `--help` to get a detailed list of supported options.

In most cases you will configure with the following command:
```
./configure
```

On Windows, FreeBSD and NetBSD you have to disable the NLS support:
```
./configure --disable-nls
```

## Build

After configuration is successful, you can build the library by running:
```
make
```

After building, it is good practice to run the unit tests before installing
the library.  The unit tests are built and executed using:
```
make test
```
And unit tests are executed by running the `bin/porion_harness` test program.

## Installation
The installation is done by running the `install` target:

```
make install
```

If you want to install on a specific place, you can change the `prefix`
and indicate the installation direction as follows:

```
make install prefix=/opt
```

