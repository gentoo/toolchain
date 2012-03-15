# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gcc/Attic/gcc-4.0.0.ebuild,v 1.7 2005/07/08 19:07:22 eradicator dead $

PATCH_VER="1.1"
UCLIBC_VER="1.0"
HTB_VER="1.00"

inherit toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"

LICENSE="GPL-2 LGPL-2.1"
KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	>=sys-devel/binutils-2.15.97"

src_unpack() {
	toolchain_src_unpack
	cd "${S}"
	[[ ! -e /root/gcc4/list ]] && return 0
	for x in $(</root/gcc4/list) ; do
		[[ -f /root/gcc4/${x} ]] && epatch "/root/gcc4/${x}"
	done
}

pkg_postinst() {
	toolchain_pkg_postinst

	einfo "This gcc-4 ebuild is provided for your convenience, and the use"
	einfo "of this compiler is not supported by the Gentoo Developers."
	einfo "Please file bugs related to gcc-4 with upstream developers."
	einfo "Compiler bugs should be filed at http://gcc.gnu.org/bugzilla/"
}
