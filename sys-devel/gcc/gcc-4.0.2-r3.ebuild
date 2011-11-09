# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/Attic/gcc-4.0.2-r3.ebuild,v 1.20 2006/12/30 11:33:36 vapier dead $

PATCH_VER="1.6"
PATCH_GCC_VER="4.0.2"
UCLIBC_VER="1.0"
UCLIBC_GCC_VER="4.0.0"
PIE_VER="8.7.8"
PIE_GCC_VER="4.0.0"
PP_VER=""
HTB_VER="1.00"

# bug #118361 and bug #108231
# I will remove them on the next revbump, unless a better fix is made by then
# - Halcy0n
GENTOO_PATCH_EXCLUDE="30_all_gcc4-pr22252.patch 35_all_gcc41-pr25010.patch"

# whether we should split out specs files for multiple {PIE,SSP}-by-default
# and vanilla configurations.
SPLIT_SPECS=no #${SPLIT_SPECS-true} hard disable until #106690 is fixed

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	>=${CATEGORY}/binutils-2.15.94"

src_unpack() {
	toolchain_src_unpack

	use vanilla && return 0

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	# Fix cross-compiling
	epatch "${FILESDIR}"/4.0.2/gcc-4.0.2-cross-compile.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${FILESDIR}"/4.0.2/gcc-4.0.2-softfloat.patch
}
