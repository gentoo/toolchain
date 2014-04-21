# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCC_FILESDIR="${PORTDIR}/sys-devel/gcc/files"

inherit eutils toolchain

DESCRIPTION="The GNU Compiler Collection."

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	>=${CATEGORY}/binutils-2.16.1"

src_prepare() {
	toolchain_src_prepare

	use vanilla && return 0

	# Fix cross-compiling
	epatch "${GCC_FILESDIR}"/4.1.0/gcc-4.1.0-cross-compile.patch
}

pkg_postinst() {
	toolchain_pkg_postinst

	einfo "This GCC ebuild is provided for your convenience, and the use"
	einfo "of this compiler is not supported by the Gentoo Developers."
	einfo "Please report bugs to upstream at http://gcc.gnu.org/bugzilla/"
}
