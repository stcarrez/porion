NAME=porion
GPRPATH=${NAME}.gpr
VERSION=x.x.x
#GPRPATH_AGENT=porion_agent.gpr

-include Makefile.conf

include Makefile.defaults

DIST_DIR=porion-$(VERSION)
DIST_FILE=porion-$(VERSION).tar.gz
ROOT_DIR=$(shell pwd)

GPRFLAGS += -j$(PROCESSORS) -XROOT_DIR=$(ROOT_DIR)

ifeq (${HAVE_DYNAMO},yes)
GPRFLAGS += -XBUILD_DYNAMO=no
else
GPRFLAGS += -XBUILD_DYNAMO=yes
DYNAMO=$(ROOT_DIR)/bin/dynamo
endif

ifeq (${HAVE_ARE},yes)
GPRFLAGS += -XBUILD_ARE=no
ARE=are
else
GPRFLAGS += -XBUILD_ARE=yes
ARE=$(ROOT_DIR)/bin/are
endif

LIBNAME=lib${NAME}

# Model generation arguments with Dynamo
# --package XXX.XXX.Models db uml/xxx.zargo
DYNAMO_ARGS=\
  --package Porion.Queries \
  --package Porion.Nodes.Models \
  --package Porion.Builds.Models \
  --package Porion.Metrics.Models \
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

build:: setup
	$(GNATMAKE) $(GPRFLAGS) -p -P "$(GPRPATH)" $(MAKE_ARGS)

server build-server::
	cd server && $(GNATMAKE) $(GPRFLAGS) -p -P "porion_server" $(MAKE_ARGS)

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
	cd server && rm -rf $(DIST_DIR)
	cd server && dynamo dist $(DIST_DIR) package.xml
	cd server && tar czf ../$(DIST_FILE) $(DIST_DIR)

build-ts:
	tsc server/web/js/projects.ts
	tsc server/web/js/builds.ts

setup:: src/porion-configs-setup.ads
src/porion-configs-setup.ads:   Makefile.conf src/porion-configs-setup.gpb
	gnatprep -DPREFIX='"${prefix}"' -DVERSION='"$(VERSION)"' \
		  src/porion-configs-setup.gpb src/porion-configs-setup.ads

ifneq (${HAVE_DYNAMO},yes)
setup:: awa/dynamo/src/gen-configs.ads
awa/dynamo/src/gen-configs.ads:   Makefile.conf awa/dynamo/src/gen-configs.gpb
	gnatprep -DCONFIG_DIR='"$(ROOT_DIR)/awa/dynamo/config"' -DVERSION='"1.2.3"' \
		  awa/dynamo/src/gen-configs.gpb awa/dynamo/src/gen-configs.ads

setup:: awa/ada-ado/src/drivers/ado-drivers-initialize.adb
awa/ada-ado/src/drivers/ado-drivers-initialize.adb: awa/ada-ado/src/drivers/ado-drivers-initialize.gpb Makefile.conf
	gnatprep -DHAVE_MYSQL=False \
	          -DHAVE_SQLITE=True \
	          -DHAVE_POSTGRESQL=False \
		  awa/ada-ado/src/drivers/ado-drivers-initialize.gpb $@

endif

install::
	mkdir -p $(DESTDIR)$(prefix)/bin
	$(INSTALL) bin/porion $(DESTDIR)$(prefix)/bin/porion
	mkdir -p $(DESTDIR)$(prefix)/share/man/man1
	$(INSTALL) docs/porion.1 $(DESTDIR)$(prefix)/share/man/man1/porion.1
	(cd share && tar --exclude='*~' -cf - .) \
       | (cd $(DESTDIR)$(prefix)/share/ && tar xf -)
