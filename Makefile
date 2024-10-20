NAME=porion
GPRPATH=${NAME}.gpr
UTIL_OS=linux64
PACKAGE_XML=package.xml
#GPRPATH_AGENT=porion_agent.gpr
# BUILD_COMMAND=$(GNATMAKE) -m -p -Patlas $(MAKE_ARGS)
VERSION=0.16.0

DIST_DIR=porion-$(VERSION)
DIST_FILE=porion-$(VERSION).tar.gz

MAKE_ARGS += -XPORION_BUILD=$(BUILD) -XAWA_BUILD=$(BUILD) -XADO_BUILD=$(BUILD) -XOPENAPI_BUILD=$(BUILD)
MAKE_ARGS += -XUTIL_BUILD=$(BUILD) -XEL_BUILD=$(BUILD) -XDYNAMO_BUILD=$(BUILD) -XSERVLET_BUILD=$(BUILD)
MAKE_ARGS += -XWIKI_BUILD=$(BUILD) -XSECURITY_BUILD=$(BUILD) -XARE_BUILD=$(BUILD)

AYACC=ayacc
AFLEX=aflex
DYNAMO=$(ALR) exec -- dynamo

-include Makefile.conf

include Makefile.defaults

UTIL_AWS_VERSION=3

ROOT_DIR=$(shell pwd)

GPRFLAGS += -j$(PROCESSORS) -XROOT_DIR=$(ROOT_DIR) -XUTIL_OS=$(UTIL_OS) -XUTIL_AWS_IMPL=$(UTIL_AWS_VERSION)

ifeq (${HAVE_DYNAMO},yes)
GPRFLAGS += -XBUILD_DYNAMO=no
PRJ_PATH=$(ROOT_DIR)/ansi-ada
else
GPRFLAGS += -XBUILD_DYNAMO=yes
ifdef ADA_PROJECT_PATH
PRJ_PATH?=${ADA_PROJECT_PATH}:
endif
PRJ_PATH:=$(PRJ_PATH)$(ROOT_DIR)/awa/ada-util/.alire:$(ROOT_DIR)/awa/ada-util/.alire/xml:$(ROOT_DIR)/awa/ada-util/.alire/aws
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-util/.alire/unit
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-util
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-el/.alire
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-el
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-keystore/.alire:$(ROOT_DIR)/awa/ada-keystore
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-ado/.alire/sqlite:$(ROOT_DIR)/awa/ada-ado/.alire/mysql
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-ado/.alire/postgresql:$(ROOT_DIR)/awa/ada-ado/.alire/all
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-ado/.alire:$(ROOT_DIR)/awa/ada-ado
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-security/.alire:$(ROOT_DIR)/awa/ada-security
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-servlet/.alire:$(ROOT_DIR)/awa/ada-servlet/.alire/aws
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-servlet:$(ROOT_DIR)/awa/ada-asf/.alire
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-asf:$(ROOT_DIR)/awa/ada-wiki/.alire
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/ada-wiki:$(ROOT_DIR)/awa/ada-wiki/.alire
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/openapi-ada/.alire:$(ROOT_DIR)/awa/dynamo
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/openapi-ada/.alire/server
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/awa/.alire:$(ROOT_DIR)/awa/awa
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/resource-embedder
PRJ_PATH:=$(PRJ_PATH):$(ROOT_DIR)/ansi-ada
# DYNAMO=env ADA_PROJECT_PATH="$(PRJ_PATH)" DYNAMO_SEARCH_PATH="$(ROOT_DIR)/awa/plugins" DYNAMO_UML_PATH="$(ROOT_DIR)/awa/uml" $(ROOT_DIR)/bin/dynamo
# DYNAMO=env DYNAMO_SEARCH_PATH="$(ROOT_DIR)/awa/plugins" DYNAMO_UML_PATH="$(ROOT_DIR)/awa/uml" $(ROOT_DIR)/bin/dynamo
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
  --package Porion.Queries.Server \
  --package Porion.Notifications.Models \
  --package Porion.Beans \
  db ../uml/porion.zargo

ROOTDIR=.

# Build executables for all mains defined by the project.
build-test::

build:: lib-setup
	$(BUILD_COMMAND) $(GPRFLAGS) $(MAKE_ARGS)

server build-server::
	cd server && $(GNATMAKE) $(GPRFLAGS) -p -P "porion_server" $(MAKE_ARGS)

test:	build
	bin/porion_harness -v -config test.properties -xml porion-aunit.xml

generate:: build-dynamo
	$(MAKE) generate-model

generate-model::
	mkdir -p db agent/db
	$(DYNAMO) generate $(DYNAMO_ARGS)
	$(DYNAMO) -C agent generate $(AGENT_DYNAMO_ARGS)
	cd agent && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration --list-access --content-only --name-access .. .
	$(DYNAMO) -C server generate $(SERVER_DYNAMO_ARGS)
	cd server && $(ARE) -o src/model --rule=are-package.xml --no-type-declaration \
          --list-access --content-only --name-access ../awa/awa .. .

package: server-package
	cd server && tar czf ../$(DIST_FILE) $(DESTDIR)$(DIST_DIR)

server-package:
	cd server && rm -rf $(DESTDIR)$(DIST_DIR)
	cd server && $(DYNAMO) dist $(DESTDIR)$(DIST_DIR) $(PACKAGE_XML)

build-ts:
	tsc server/web/js/projects.ts server/web/js/builds.ts server/web/js/xunits.ts \
            server/web/js/nodes.ts \
            server/web/js/activity.ts \
            server/web/js/notifications.ts

lib-setup:: src/porion-configs-setup.ads
src/porion-configs-setup.ads:   Makefile.conf src/porion-configs-setup.gpb
	$(GNATPREP) -DPREFIX='"${prefix}"' -DVERSION='"$(VERSION)"' \
		  src/porion-configs-setup.gpb src/porion-configs-setup.ads

ifneq (${HAVE_DYNAMO},yes)
lib-setup:: awa/dynamo/src/gen-configs.ads
awa/dynamo/src/gen-configs.ads:   Makefile.conf awa/dynamo/src/gen-configs.gpb
	cd awa/dynamo && sh ./alire-setup.sh

# Install the AWA UML model in Dynamo UML search path
awa/dynamo/config/uml/AWA.xmi: awa/awa/uml/awa.zargo
	unzip -cq awa/awa/uml/awa.zargo awa.xmi > awa/dynamo/config/uml/AWA.xmi

build-dynamo: bin/dynamo awa/dynamo/config/uml/AWA.xmi

bin/dynamo: setup
	$(BUILD_COMMAND) $(GPRFLAGS) $(MAKE_ARGS)
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
	rm -rf awa/obj awa/ada-ado/obj awa/ada-util/obj awa/ada-el/obj awa/ada-asf/obj \
               awa/ada-keystore/obj awa/ada-security/obj awa/ada-servlet/obj \
               awa/openapi-ada/obj awa/ada-wiki/obj

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

# Development targets that requires ayacc and aflex to be installed.
# Do not call these unless you modify the lex/yacc grammar.
parser:	
	cd src/parser && \
	   $(AYACC) -n 256 -v -k -P -s -e .ada porion-templates-parser-parser.y && \
	   gnatchop -w porion-templates-parser-parser.ada && \
	   rm -f porion-templates-parser-parser.ada
	# -rm -f src/parser/porion-templates-parser-parser.verbose

lexer:
	cd src/parser; \
	  $(AFLEX) -ms -P -L porion-templates-parser-lexer.l
	cd src/parser && \
	  gnatchop -w porion-templates-parser-lexer.ada && \
	  rm -f porion-templates-parser-lexer.ada

info:
	$(DYNAMO) info
	cd server && $(DYNAMO) info
