NAME=porion
GPRPATH=${NAME}.gpr
GPRPATH_AGENT=porion_agent.gpr

-include Makefile.conf

include Makefile.defaults

LIBNAME=lib${NAME}

ARE=are

# Model generation arguments with Dynamo
# --package XXX.XXX.Models db uml/xxx.zargo
DYNAMO_ARGS=\
  --package Porion.Nodes.Models \
  --package Porion.Builds.Models \
  --package Porion.XUnit.Models \
  --package Porion.Projects.Models \
  db uml/porion.zargo

ROOTDIR=.

# Build executables for all mains defined by the project.
build-test::
	#$(GNATMAKE) $(GPRFLAGS) -p -P$(NAME)_tests $(MAKE_ARGS)

build::
	$(GNATMAKE) -m -p -P "$(GPRPATH_AGENT)" $(MAKE_ARGS)
	$(GNATMAKE) -m -p -P "$(GPRPATH)" $(MAKE_ARGS)

test:	build
	bin/porion_harness -v -config test.properties -xml porion-aunit.xml

generate::
	mkdir -p db
	$(DYNAMO) generate $(DYNAMO_ARGS)
	$(ARE) -o src/model --rule=are-package.xml --list-access --content-only --name-access .
