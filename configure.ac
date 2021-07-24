dnl Autoconf configure script for porion

dnl Process this file with autoconf to produce a configure script.

AC_INIT(src/porion.ads)

AM_GNAT_LIBRARY_PROJECT(porion)

# Current release settings
PORION_MAJOR_VERSION=0
PORION_MINOR_VERSION=1
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


if test T$GETTEXT_INTL = TTrue; then
  USE_LIBINTL=yes
else
  USE_LIBINTL=no
fi
AC_SUBST(USE_LIBINTL)

AM_GNAT_FIND_ADA_UTIL([porion])
AM_GNAT_FIND_ADA_EL([porion])
AM_GNAT_FIND_ADA_SECURITY([porion])
AM_GNAT_FIND_ADA_SERVLET([porion])
AM_GNAT_FIND_ADA_SERVER_FACES([porion])
AM_GNAT_FIND_ADA_ADO([porion])
AM_GNAT_FIND_ADA_WIKI([porion])
AM_GNAT_FIND_ADA_OPENAPI([porion])
AM_GNAT_FIND_ADA_AWA([porion])

AC_OUTPUT(
Makefile.conf porion_agent.gpr porion_server.gpr porion_lib.gpr porion_tests.gpr
)
