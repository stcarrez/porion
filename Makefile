NAME=porion
GPRPATH=${NAME}.gpr
VERSION=x.x.x
UTIL_OS=linux64
PACKAGE_XML=package.xml
#GPRPATH_AGENT=porion_agent.gpr

-include Makefile.conf

include Makefile.defaults

DIST_DIR=porion-$(VERSION)
DIST_FILE=porion-$(VERSION).tar.gz
ROOT_DIR=$(shell pwd)

GPRFLAGS += -j$(PROCESSORS) -XROOT_DIR=$(ROOT_DIR) -XUTIL_OS=$(UTIL_OS) -XUTIL_AWS_IMPL=$(UTIL_AWS_VERSION)

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
  --package Porion.Audits.Models \
  db ../uml/porion.zargo

SERVER_DYNAMO_ARGS=\
  --package Porion.Beans \
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

generate:: build-dynamo
	$(MAKE) generate-model

generate-model::
	mkdir -p db agent/db
	$(DYNAMO) generate $(DYNAMO_ARGS)
	cd agent && $(DYNAMO) generate $(AGENT_DYNAMO_ARGS)
	cd agent && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration --list-access --content-only --name-access .. .
	cd server && $(DYNAMO) generate $(SERVER_DYNAMO_ARGS)
	cd server && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration \
          --list-access --content-only --name-access ../awa/awa .. .

package: server-package
	cd server && tar czf ../$(DIST_FILE) $(DESTDIR)$(DIST_DIR)

server-package:
	cd server && rm -rf $(DESTDIR)$(DIST_DIR)
	cd server && $(DYNAMO) dist $(DESTDIR)$(DIST_DIR) $(PACKAGE_XML)

build-ts:
	tsc server/web/js/projects.ts server/web/js/builds.ts server/web/js/xunits.ts server/web/js/nodes.ts

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

# Install the AWA UML model in Dynamo UML search path
awa/dynamo/config/uml/AWA.xmi: awa/awa/uml/awa.zargo
	unzip -cq awa/awa/uml/awa.zargo awa.xmi > awa/dynamo/config/uml/AWA.xmi

build-dynamo: bin/dynamo awa/dynamo/config/uml/AWA.xmi

bin/dynamo: setup
	$(GNATMAKE) $(GPRFLAGS) -p -P "$(GPRPATH)" $(MAKE_ARGS)
else

build-dynamo:

endif

install::
	mkdir -p $(DESTDIR)$(prefix)/bin
	$(INSTALL) bin/porion $(DESTDIR)$(prefix)/bin/porion
	mkdir -p $(DESTDIR)$(prefix)/share/man/man1 $(DESTDIR)$(prefix)/share/man/man8
	$(INSTALL) docs/man1/porion.1 $(DESTDIR)$(prefix)/share/man/man1/porion.1
	$(INSTALL) docs/porion-server.8 $(DESTDIR)$(prefix)/share/man/man8/porion-server.8
	(cd share && tar --exclude='*~' -cf - .) \
       | (cd $(DESTDIR)$(prefix)/share/ && tar xf -)

clean::
	rm -rf server/$(DIST_DIR)

PORION_DOC= \
  title.md \
  pagebreak.tex \
  index.md \
  pagebreak.tex \
  Installation.md \
  pagebreak.tex

DOC_OPTIONS=-f markdown
DOC_OPTIONS+= --listings --number-sections --toc
HTML_OPTIONS=-f markdown
HTML_OPTIONS+= --listings --number-sections --toc --css docs/pandoc.css

$(eval $(call pandoc_build,porion-book,$(PORION_DOC)))
