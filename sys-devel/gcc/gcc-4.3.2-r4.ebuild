# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/gcc-4.3.2-r4.ebuild,v 1.9 2010/01/09 12:58:57 ulm Exp $

PATCH_VER="1.8"
UCLIBC_VER="1.0"

# Hardened gcc 4 stuff
PIE_VER="10.1.5"
PIE_GCC_VER="4.3.2"
SPECS_VER="0.9.4"
SPECS_GCC_VER="4.3.2"

# arch/libc configurations known to be stable or untested with {PIE,SSP,FORTIFY}-by-default
PIE_GLIBC_STABLE="x86 amd64 ~ppc ~ppc64 ~arm ~sparc"
PIE_UCLIBC_STABLE="x86 arm"
#SSP_STABLE="amd64 x86 ppc ppc64 ~arm ~sparc"
#SSP_UCLIBC_STABLE=""

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-3 LGPL-3 || ( GPL-3 libgcc libstdc++ ) FDL-1.2"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	amd64? (
		>=sys-libs/glibc-2.7-r2
		multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) )
	)
	ppc? ( >=${CATEGORY}/binutils-2.17 )
	ppc64? ( >=${CATEGORY}/binutils-2.17 )
	>=${CATEGORY}/binutils-2.15.94"

src_unpack() {
	toolchain_src_unpack

	use vanilla && return 0

	sed -i 's/use_fixproto=yes/:/' gcc/config.gcc #PR33200

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${FILESDIR}"/gcc-spec-env.patch

	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${FILESDIR}"/4.3.2/gcc-4.3.2-softfloat.patch
}
