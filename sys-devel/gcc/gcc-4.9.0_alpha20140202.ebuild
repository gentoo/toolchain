# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
GCC_FILESDIR="${PORTDIR}/sys-devel/gcc/files"

inherit eutils toolchain

DESCRIPTION="The GNU Compiler Collection."
LICENSE="GPL-3 LGPL-3 || ( GPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.2"
KEYWORDS=""

IUSE="debug"

RDEPEND=""
DEPEND="${RDEPEND}
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	>=${CATEGORY}/binutils-2.18"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.12 )"
fi

src_prepare() {
	toolchain_src_prepare

	use debug && GCC_CHECKS_LIST="yes"

	use vanilla && return 0
	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env-r1.patch
}

pkg_postinst() {
	toolchain_pkg_postinst
	echo
	einfo "This GCC ebuild is provided for your convenience, and the use"
	einfo "of this compiler is not supported by the Gentoo Developers."
	einfo "Please report bugs to upstream at http://gcc.gnu.org/bugzilla/"
	echo
}