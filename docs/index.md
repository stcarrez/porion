# Introduction

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

![Porion Overview](images/porion-overview.png)

This document describes how to build the tool and how you can use it.
