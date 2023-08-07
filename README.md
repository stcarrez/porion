# Porion

[![License](http://img.shields.io/badge/license-APACHE2-blue.svg)](LICENSE)
[![Build Status](https://img.shields.io/endpoint?url=https://porion.vacs.fr/porion/api/v1/projects/porion/badges/build.json)](https://porion.vacs.fr/porion/projects/view/porion/summary)
[![Test Status](https://img.shields.io/endpoint?url=https://porion.vacs.fr/porion/api/v1/projects/porion/badges/tests.json)](https://porion.vacs.fr/porion/projects/view/porion/xunits)
[![Coverage](https://img.shields.io/endpoint?url=https://porion.vacs.fr/porion/api/v1/projects/porion/badges/coverage.json)](https://porion.vacs.fr/porion/projects/view/porion/summary)
[![semver](https://img.shields.io/badge/semver-2.0.0-blue.svg?cacheSeconds=2592000)]()

# TL;DR

Porion is an automation system that helps automate the building, testing and
deployment of software development projects.

First create the porion workspace directory:
```
   porion init workspace-dir
```

Then register a project to build:
```
   porion add https://github.com/stcarrez/ada-util.git
   porion add project-2.0.tar.gz
```

Build a project from the build queue or build a specific project:
```
   porion build
   porion build ada-util
   porion build project-2.0
```

Check for changes in sources and update the build queue:
```
   porion check
```

Add a remote build node:
```
   porion node ssh://user@hostname/home/build-directory
```

Add a build recipe on a project:
```
   porion add --recipe=remote ada-util@hostname
```

Get information about a project or a build number:
```
   porion info ada-util
   porion info ada-util:2
```

Version 0.14.0 - Apr 2023
  - Fix adding a recipe on a new branch
  - Fix displaying the project recipes on all branches
  - Use single ssh connection for multiple commands when building on remote node
  - Copy project files using scp on remote nodes

Version 0.13.0 - Mar 2023
  - Update to use last AWA version
  - Improvement to display on mobile phones
  - Support to collect standard error as separate streams to identify these
    messages as errors
  - Prototype for build templates

[List all versions](https://gitlab.com/stcarrez/porion/blob/master/NEWS.md)

# Overview

Porion is a continuous integration server and agent that helps automate the building,
testing and deployment of software development projects written in any language.
Porion maintains a list of projects with build recipes to build these projects.
It periodically checks for changes in projects and it schedules a build when a project
is modified.  Porion uses a build node to build a project and the build node can
be the current host or a specific remote host registered for that purpose.

Porion uses a workspace directory to maintain the list of projects, their build status
and build area.  The workspace directory contains a SQLite database which is used
to maintain the list of projects, build nodes, build recipes, build queue and build
results.

The steps to use Porion are the following:

- the Porion workspace directory is created by using the `porion init` command,
- projects are registered by using the `porion add` command with enough information to
  allow Porion to checkout the source and detect changes.  When a project is added
  Porion will guess a set of build recipes for the new project.
- project build recipes and build steps are updated and configured on the project
  by using either `porion add --recipe` or `porion step` commands.


# Porion commands

`porion` provides the following commands:

* `add`:      add a new project or a new recipe
* `build`:    build the project
* `check`:    check for changes and update the build queue
* `config`:   get or configure a global parameter
* `depend`:   add or remove project dependencies
* `edit`:     edit the project configuration
* `help`:     print some help
* `info`:     report some information about a project or a build
* `init`:     setup the build agent node
* `list`:     list the projects, nodes, builds
* `logs`:     display the build logs
* `node`:     add, update or remove build nodes
* `remove`:   remove a project and its build data
* `set`:      set a project, branch or recipe variable
* `status`:   status about the workspace or a project
* `step`:     control the build steps

# Porion Debian Binaries

Ubuntu 20.04 packages are available to help you install the `porion`
and `porion-server` commands more easily.  You can configure your Ubuntu system as follows:

```
wget -O - https://apt.vacs.fr/apt.vacs.fr.gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://apt.vacs.fr/ubuntu-focal focal main"
```

And then install the `porion-server` package:

```
sudo apt-get install porion-server
```

# Building Porion

To build `porion` you will need the GNAT Ada compiler, either
the FSF version available in Debian, FreeBSD systems NetBSD or the
AdaCore GNAT Community 2021 edition.

## Development Host Installation

### Ubuntu

Install the following packages:
```
sudo apt-get install -y make gnat gprbuild git libsqlite3-dev
```

### FreeBSD 12

Install the following packages:

```
pkg install gmake gcc6-aux-20180516_1,1 gprbuild-20160609_1 git
pkg install lzma-18.05 curl-7.66.0 xmlada-17.0.0_1 aws-17.1_2 sqlite3-3.29.0
```

## Getting the sources

The project uses a sub-module to help you in the integration and build
process.  You should checkout the project with the following commands:

```
git clone --recursive https://gitlab.com/stcarrez/porion.git
cd porion
```

## Configuration

To configure `porion`, use the following command:
```
./configure
```

## Build

Then, build the application:
```
make
```

And install it:
```
make install
```

# Documents

* Man page: [porion (1)](https://gitlab.com/stcarrez/porion/blob/master/docs/porion.md)
* Man page: [porion-server (8)](https://gitlab.com/stcarrez/porion/blob/master/docs/porion-server.md)

# Presentations

* [Implementing a build manager in Ada](https://www.slideshare.net/StephaneCarrez1/implementing-a-build-manager-in-ada)

# Sites Using Porion

* [Porion Build Manager](https://porion.vacs.fr/porion/index.html)

# Porion server development setup

Typescript development setup:

```
pkg install npm-node18-8.13.0
npm install typescript --save-dev
npm install --save @types/jquery
npm install --save @types/flot
```

To build the Javascript files:

```
make build-ts
```
