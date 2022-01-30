
## NAME

porion-server - Continuous build system

## SYNOPSIS

*porion-server* [ -v ] [-vv] [-vvv] [-V] [ -c
_config-file_ ]
_command_  [args]


## DESCRIPTION

_porion-server_ is a continuous integration server that helps automate the building,
testing and deployment of software development projects written in any language.
_porion-server_ maintains a list of projects with build recipes to build these projects.
It periodically checks for changes in projects and schedules a build when a project
is modified.  _porion-server_ uses a build node to build a project and the build node can
be the current host or a specific remote host registered for that purpose.

_porion_ uses a workspace directory to maintain the list of projects, their build status
and build area.  The workspace directory contains a SQLite database which is used
to maintain the list of projects, build nodes, build recipes, build queue and build
results.


## OPTIONS

The following options are recognized by _porion-server_:


-V
Prints the
_porion-server_ version.


-v
Enable the verbose mode.


-vv
Enable debugging output.


-vvv
Enable full debugging output.


-c
_config-file_ Defines the path of the global
_porion_ configuration file.

## COMMANDS



### The init command
```
porion-server init directory
```

Setup the build workspace directory used by the porion server and porion build agent.
This directory is created by the command and is used for:

* the SQLite database that describes projects, builds, tests

* the project directories where projects are built


### The start command
```
porion-server start [--management-port PORT] [--port PORT]
    [--connection COUNT] [--upload DIR] [--tcp-no-delay]
    [--daemon] [--keystore PATH]
```

The
_start_ command allows to start the server and all applications that are
registered to the web container.  When a keystore is specified, it is first
unlocked by using one of the unlock mechanism (password, GPG, ...).
Then, each application is configured by using its own configuration file
and a subset of the keystore secured configuration.
Once each application is configured, the web server container is started
to listen to the TCP/IP port defined by the
.BI --port= PORT
option.
Applications are then started and they can serve HTTP requests through
the web server container.

At the same time, a management port is created and used exclusively by
the
_stop_ command to stop the web server container.  The
_start_ command
will wait on that management port for the
_stop_ command to be executed.
The management port is configured by the
.BI --management= PORT
option.
The management port is local to the host and cannot be accessed remotely.

When the
*--daemon* option is used, the server will first put itself in
the background.  This option is supported only under some Unix systems
like
_GNU/Linux_ and
_FreeBSD_ and more generally every system where
the
_daemon_(3) C-library call is supported.  On other systems, this option
has no effect.

The
*--tcp-no-delay* option is supported for recent version of
Ada Web Server and configure the web server to use the
_TCP_NO_DELAY_ option of the TCP/IP stack (strongly recommended).

The
.BI --upload= DIR
option indicates to the web server container
the directory that can be used to store temporarily the uploaded files
that the server receives.

The
.BI --connection= COUNT
option controls the maximum number of active
HTTP requests that the server can handle.


### The setup command
```
porion-server setup [--management-port PORT] [--port PORT]
   [--connection COUNT] [--upload DIR] [--tcp-no-delay]
   [--daemon] [--keystore \fIPATH\f] NAME
```

The
_setup_ command is very close to the
_start_ command but it starts
the
*Setup Application* to configure the application by using a web browser.


### The stop command
```
porion-server stop [--management-port PORT] [--keystore PATH]
```

The
_stop_ command is used to inform a running web server container to stop.
The management port is used to connect to the web server container and stop it.
The management port is local to the host and cannot be accessed remotely.

The management port is configured with the
.BI --management-port= PORT
option.


### The list command
```
porion-server list [--application NAME] [--keystore PATH]
     [--users] [--jobs] [--sessions] [--tables]
```

The
_list_ command is intended to help in looking at the application
database and see some important information.  Because the database is
specific to each application, it may be necessary to indicate the
application name by using the
.BI --application= NAME
option.

The
*--tables* option triggers the list of database tables with the
number of entries they contain.

The
*--users* option triggers the list of users that are registered in
the application.

The
*--sessions* option triggers the list of user connection sessions.

The
*--jobs* option triggers the list of jobs that have been created
and scheduled.


### The info command
```
porion-server info [--application NAME] [--keystore PATH]
   [--long-lines]
```

The
_info_ command reports the current configuration used by the
application.  The configuration is extracted from the AWA default
XML configuration files and can be overriden by the application
specific configuration.  The command allows to see what is the
actual configuration.  The configuration is printed with the
configuration name and its associated value.

The list of configuration parameters are grouped in several categories:

* _Database configuration_ gives the configuration properties for the
database configuration.

* _Server faces configuration_ lists the configuration use by the Ada Servlets and Ada Server Faces.

* _AWA Application_ lists the core AWA configuration properties.

Depending on whether a module is used by the application, a number
of modules are listed with their configuration.

The
*--long-lines* option triggers the list of database tables with the
number of entries they contain.

## CONFIGURATION

The
_porion_ global configuration file contains several configuration properties
which are used to customize several commands.  These properties can
be modified with the
*config* command.


### workspace_dir
This property defines the absolute path of the
_porion_ workspace directory.


### project_dir
This property defines the absolute path where project directories
are stored.  The default is
_workspace_dir_/projects. 

### rules_dir
This property defines the path of the rules directory which contains
description of filtering rules that can be configured in a project recipe.

## SEE ALSO

_porion(1)_,
_cron(8)_

## AUTHOR

Written by Stephane Carrez.

