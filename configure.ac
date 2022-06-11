dnl Autoconf configure script for porion

dnl Process this file with autoconf to produce a configure script.

AC_INIT
AC_CONFIG_SRCDIR([src/porion.ads])

AM_GNAT_LIBRARY_PROJECT(porion)

# Current release settings
PORION_MAJOR_VERSION=0
PORION_MINOR_VERSION=8
PORION_MICRO_VERSION=0
PORION_VERSION=$PORION_MAJOR_VERSION.$PORION_MINOR_VERSION.$PORION_MICRO_VERSION

# Set the version number of the project
AC_SUBST(PORION_VERSION)
AC_SUBST(PORION_MAJOR_VERSION)
AC_SUBST(PORION_MINOR_VERSION)
AC_SUBST(PORION_MICRO_VERSION)

PORION_LIBDIR="lib"
AC_SUBST(PORION_LIBDIR)

AM_ADA_UTIL_HARDWARE()
AM_ADA_UTIL_AWS_VERSION()

case "${target_os}" in
  mingw32*|cygwin*|mingw64*|msys)
    HAVE_GETTEXT=False
    GETTEXT_INTL=False
    ;;

  netbsd*|dragonfly*|openbsd*|freebsd*)
    HAVE_GETTEXT=False
    GETTEXT_INTL=False
    ;;
  
  *)
    AM_GNU_GETTEXT([external])
    ;;

esac

if test T$HAVE_GETTEXT = TTrue; then
  USE_NLS=yes
else
  USE_NLS=no
fi
AC_SUBST(USE_NLS)

ac_enable_server=no
AC_ARG_ENABLE(server,
  [  --enable-server         Enable compilation of Porion server],
  [case "${enableval}" in
    no|none)  ac_enable_server= ;;
    *)        ac_enable_server=yes
		  	  ;;
  esac])

PORION_SERVER=${ac_enable_server}
AC_SUBST(PORION_SERVER)

if test T$GETTEXT_INTL = TTrue; then
  USE_LIBINTL=yes
else
  USE_LIBINTL=no
fi
AC_SUBST(USE_LIBINTL)

AC_CHECK_PROG(HAVE_PANDOC,pandoc,yes)
AC_CHECK_PROG(HAVE_DYNAMO,dynamo,yes)
AC_CHECK_PROG(HAVE_ARE,are,yes)

AWA_DIR=""
ADO_DIR=""
EL_DIR=""
UTIL_DIR=""
SERVLET_DIR=""
ASF_DIR=""
KEYSTOREADA_DIR=""
SECURITY_DIR=""
AC_SUBST(AWA_DIR)
AC_SUBST(ADO_DIR)
AC_SUBST(EL_DIR)
AC_SUBST(UTIL_DIR)
AC_SUBST(SERVLET_DIR)
AC_SUBST(ASF_DIR)
AC_SUBST(KEYSTOREADA_DIR)
AC_SUBST(SECURITY_DIR)

ROOT_DIR=`pwd`
GNAT_PROJECT_PATHS="$ROOT_DIR/awa/ada-util/.alire:$ROOT_DIR/awa/ada-util/.alire/xml:$ROOT_DIR/awa/ada-util/.alire/aws:$ROOT_DIR/awa/ada-util/.alire/unit"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-util:$ROOT_DIR/awa/ada-el/.alire:$ROOT_DIR/awa/ada-el:$ROOT_DIR/awa/ada-keystore/.alire"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-keystore:$ROOT_DIR/awa/ada-ado/.alire/sqlite:$ROOT_DIR/awa/ada-ado/.alire/mysql"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-ado/.alire/postgresql:$ROOT_DIR/awa/ada-ado/.alire/all:$ROOT_DIR/awa/ada-ado/.alire"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-ado:$ROOT_DIR/awa/ada-security/.alire:$ROOT_DIR/awa/ada-security:$ROOT_DIR/awa/ada-servlet/.alire"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-servlet/.alire/aws:$ROOT_DIR/awa/ada-servlet:$ROOT_DIR/awa/ada-asf/.alire:$ROOT_DIR/awa/ada-asf"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/ada-wiki/.alire:$ROOT_DIR/awa/ada-wiki:$ROOT_DIR/awa/ada-wiki/.alire:$ROOT_DIR/awa/openapi-ada/.alire"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:$ROOT_DIR/awa/dynamo/.alire:$ROOT_DIR/awa/.alire:$ROOT_DIR/awa/awa"
GNAT_PROJECT_PATHS="$GNAT_PROJECT_PATHS:/usr/share/gpr"

AC_SUBST(GNAT_PROJECT_PATHS)

BUNDLE_DIR="$ROOT_DIR/awa/ada-asf/bundles"
AC_SUBST(BUNDLE_DIR)

DYNAMO_SEARCH_DIR="$ROOT_DIR/awa/awa/plugins"
AC_SUBST(DYNAMO_SEARCH_DIR)

AC_CONFIG_FILES([Makefile.conf agent/porion_agent.gpr server/porion_server.gpr porion_lib.gpr porion_tests.gpr
awa/dynamo/config/generator.properties
])
AC_OUTPUT
