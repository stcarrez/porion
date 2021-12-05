dnl Autoconf configure script for porion

dnl Process this file with autoconf to produce a configure script.

AC_INIT(src/porion.ads)

AM_GNAT_LIBRARY_PROJECT(porion)

# Current release settings
PORION_MAJOR_VERSION=0
PORION_MINOR_VERSION=2
PORION_MICRO_VERSION=0
PORION_VERSION=$PORION_MAJOR_VERSION.$PORION_MINOR_VERSION.$PORION_MICRO_VERSION

# Set the version number of the project
AC_SUBST(PORION_VERSION)
AC_SUBST(PORION_MAJOR_VERSION)
AC_SUBST(PORION_MINOR_VERSION)
AC_SUBST(PORION_MICRO_VERSION)

PORION_LIBDIR="lib"
AC_SUBST(PORION_LIBDIR)

case "${target_os}" in
  mingw32*|cygwin*|mingw64*|msys)
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

AWA_DIR=""
ADO_DIR=""
EL_DIR=""
UTIL_DIR=""
SERVLET_DIR=""
ASF_DIR=""
KEYSTOREADA_DIR=""
AC_SUBST(AWA_DIR)
AC_SUBST(ADO_DIR)
AC_SUBST(EL_DIR)
AC_SUBST(UTIL_DIR)
AC_SUBST(SERVLET_DIR)
AC_SUBST(ASF_DIR)
AC_SUBST(KEYSTOREADA_DIR)

AC_OUTPUT(
Makefile.conf agent/porion_agent.gpr server/porion_server.gpr porion_lib.gpr porion_tests.gpr
)
