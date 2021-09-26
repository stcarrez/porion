NAME=porion
GPRPATH=${NAME}.gpr
#GPRPATH_AGENT=porion_agent.gpr

-include Makefile.conf

include Makefile.defaults

LIBNAME=lib${NAME}

ARE=are

# Model generation arguments with Dynamo
# --package XXX.XXX.Models db uml/xxx.zargo
DYNAMO_ARGS=\
  --package Porion.Queries \
  --package Porion.Nodes.Models \
  --package Porion.Builds.Models \
  --package Porion.XUnit.Models \
  --package Porion.Projects.Models \
  db uml/porion.zargo

AGENT_DYNAMO_ARGS=\
  db

SERVER_DYNAMO_ARGS=\
  --package Porion.Dashboards.Models \
  db ../uml/porion.zargo

ROOTDIR=.

# Build executables for all mains defined by the project.
build-test::

build::
	$(GNATMAKE) -m -p -P "$(GPRPATH)" $(MAKE_ARGS)

server build-server::
	cd server && $(GNATMAKE) -m -p -P "porion_server" $(MAKE_ARGS)

test:	build
	bin/porion_harness -v -config test.properties -xml porion-aunit.xml

generate::
	mkdir -p db agent/db
	$(DYNAMO) generate $(DYNAMO_ARGS)
	cd agent && $(DYNAMO) generate $(AGENT_DYNAMO_ARGS)
	cd agent && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration --list-access --content-only --name-access .. .
	cd server && $(DYNAMO) generate $(SERVER_DYNAMO_ARGS)
	cd server && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration --list-access --content-only --name-access .. .

package:
	cd server && dynamo dist porion-0.1 package.xml
