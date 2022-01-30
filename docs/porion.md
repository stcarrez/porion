
## NAME

porion - Continuous build system

## SYNOPSIS

*porion* [ -v ] [-vv] [-vvv] [-V] [ -c
_config-file_ ]
_command_  [args]


## DESCRIPTION

_porion_ is a continuous integration agent that helps automate the building,
testing and deployment of software development projects written in any language.
_porion_ maintains a list of projects with build recipes to build these projects.
It periodically checks for changes in projects and schedules a build when a project
is modified.  _porion_ uses a build node to build a project and the build node can
be the current host or a specific remote host registered for that purpose.

_porion_ uses a workspace directory to maintain the list of projects, their build status
and build area.  The workspace directory contains a SQLite database which is used
to maintain the list of projects, build nodes, build recipes, build queue and build
results.

The _porion_ agent has a server companion that is dedicated to providing web access.
The
_porion-server_(8) is the server that handles the HTTP requests.  It is not strictly necessary to run
it to build and manage the projects.

The steps to use _porion_ are the following:

* the _porion_ workspace directory is created by using the _porion init_ command,

* projects are registered by using the _porion add_ command with enough information to
allow _porion_ to checkout the source and detect changes.  When a project is added
_porion_ will guess a set of build recipes for the new project,

* project build recipes and build steps are updated and configured on the project
by using either _porion add --recipe_ or _porion step_ commands.  These build
recipes describe the steps that must be executed to build, test and deploy the project,

* source changes are detected by running the _porion check_ command.  This command can
be executed explicitly for a given project or globally from a
_cron_(8) job for example.  When it detect a change in a project, it adds the project to the
build queue,

* the build queue is processed by running the _porion build_ command.
It looks at the build queue and executes the build either on the current host or
on the build node specified by the recipe,

* when the build is finished, the user can look at the build result by
using either the _porion info_ or the _porion logs_ commands.

_porion_ uses an identification string to reference a project, a branch,
a build recipe or a build.  That identification string has the following pattern:

```
project-name[#branch-name][~recipe-name][@hostname][:build-number]
```



## OPTIONS

The following options are recognized by _porion_:


-V
Prints the
_porion_ version.


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
porion init directory
```

Setup the build workspace directory used by the porion build agent.
This directory is created by the command and is used for:

* the SQLite database that describes projects, builds, tests

* the project directories where projects are built


### The add command
```
porion add url
```
```
porion add --recipe {name} {ident} [source-ident]
```

The _porion add_ command is used to add a new project or a new recipe to an existing project.
The first form creates a new project with the source scheme.
A default project name is created from the source scheme name
and a set of build recipes are guessed by analysing the sources.

The second form adds a new recipe with the given identification and initializes
it from either the main project recipe or from the given source identification
recipe.  You may also specify a build number as the identification in which case
the recipe used by that build number will be copied.


### The build command
```
porion build project
```

For each active branch of the project, check if some changes are pending
or if a build is required and build the project on the branch.
When --force is given, run the build even if no changes are detected.
When --dry-run is given, don't build but print the commands that are
executed to build the project.
This command is available when the


### The check command
```
porion check [--all] [project...]
```

The
_check_ command is used to check for changes in projects and when a change is detected in a
project branch, the build recipes are added to the build queue
if that branch is active.

For each project, porion maintains a check date and a check delay
controls the periodicity of the check.  A project is checked
only when its check date has been passed or when its name is
specified in the command line.

The
_--all_ option allows to force a check for every active project.


### The config command
```
porion config keystore.akt -- name
```



### The env command
```
porion env [--unset name] {ident} [NAME=VALUE]
```

Configure the environment variables used to build a project, a branch
a specific recipe or on a build node.  The environment variable is
associated with
_ident_. 
The
_--unset name_ option allows to remove a past definition.


### The depend command
```
porion depend [--remove] project dependency1 ...
```

Add or remove a project dependency.  When a dependency project is modified
this triggers a build of the project.

The
_--remove_ option allows to remove one or several project dependencies.


### The edit command
```
porion \fBedit project
```

The
_edit_ command can be used to edit the configuration of a project.
The editor is launched
with the path and when editing is finished the temporary file is read.
The temporary directory and files are erased when the editor terminates
successfully or not.  The editor can be specified by using the
_-e_ option, by setting up the
_EDITOR_ environment variable or by updating the
_editor_(1) alternative with
_update-alternative_(1). 

### The info command
```
porion info project
```

The
_list_ command describes the entries stored in the keystore with
their name, size, type, creation date and number of keys which
protect the entry.


### The list command
```
porion list
```



### The logs command
```
porion logs [--no-filter] <ident> ...
```

Displays the logs produced by a build with the given identification.
Each identifier must define at least the project name and the build
number (the branch, recipe and build host are optional).

By default, the displayed logs are filtered according to the filtering
rules defined on the recipe.  The
_--no-filter_ option can be used to disable this filtering.

Use _porion set <recipe> filter_rules=<filter1,...,filterN>_ to configure
the recipe filtering rules.  The recipe filtering rules can be changed
after a build.


### The node command
```
porion node hostname
```



### The remove command
```
porion remove [--force] [--interactive] ident [ident...]
```

Remove a project, a recipe or a build and all its data.
When the ident string indicates a build number, only the build number
is removed.  The project rating are then updated.

When the ident string contains a recipe name, the recipe is removed
as well as all the builds that were made with it.  The project rating
are then updated.

With the
_--interactive_ option, a confirmation is asked before removal.

The
_--force_ option forces the removal and ignores any error.


### The step command
```
porion step [--quiet] [--ignore-error] [--timeout timeout]
       [--disable] [--insert pos] [--update pos]
       [--remove pos] ident command args...
```

The
_step_ command is used to add, update or remove a recipe
build step.  After updating the recipe, the list of build steps is
printed unless the
_--quiet_ option is passed.

By default a build step is added at the end of the build recipe as a last
step.  The position can be controlled by using the
_--insert_ _pos_ option.

With the
_--update_ option, the build step at the given position is replaced.

With the
_--remove_ option, the build step is removed.

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

_editor(1)_, _update-alternative(1)_, _make(1)_,
_mvn(1)_,
_cron(8)_,
_porion-server(8)_

## AUTHOR

Written by Stephane Carrez.

