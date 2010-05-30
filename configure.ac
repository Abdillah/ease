AC_INIT([Ease], [0.1], [https://bugzilla.gnome.org/enter_bug.cgi?product=ease], [ease], [http://live.gnome.org/Ease])

AC_PREREQ([2.59])

AC_CONFIG_FILES([Makefile po/Makefile.in])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([no-dist-gzip dist-bzip2 subdir-objects])

# Enable silent rules is available
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AC_PROG_CC_STDC
AM_PROG_VALAC([0.8.1])
AM_PROG_CC_C_O
AC_PROG_INSTALL
AC_PROG_INTLTOOL([0.35])

AM_PROG_LIBTOOL

dnl this is preferred, but doesn't work for me :
dnl LT_PREREQ([2.2.6])

GNOME_COMPILE_WARNINGS([maximum])
GNOME_MAINTAINER_MODE_DEFINES

dnl FIXME
pkg_modules="clutter-gtk-0.10 >= 0.10 gee-1.0 >= 0.5.0 clutter-gst-1.0 >= 1.0.0 json-glib-1.0 >= 0.7.6"

EASE_PACKAGES="--pkg glib-2.0 --pkg gtk+-2.0 --pkg clutter-1.0 --pkg gdk-2.0 --pkg libxml-2.0 --pkg gee-1.0 --pkg clutter-gtk-0.10 --pkg cogl-1.0 --pkg gio-2.0 --pkg clutter-gst-1.0"

PKG_CHECK_MODULES(EASE, [$pkg_modules])

AC_SUBST(EASE_CFLAGS)
AC_SUBST(EASE_LIBS)
AC_SUBST(EASE_PACKAGES)

dnl internationalization
GETTEXT_PACKAGE=ease
AC_DEFINE_UNQUOTED([GETTEXT_PACKAGE], ["$GETTEXT_PACKAGE"], [Gettext Package])
AC_SUBST(GETTEXT_PACKAGE)
AM_GLIB_GNU_GETTEXT
AM_GNU_GETTEXT([external])

AC_OUTPUT