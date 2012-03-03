# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

GCC_FILESDIR=${PORTDIR}/sys-devel/gcc/files

inherit multilib subversion toolchain

DESCRIPTION="The GNU Compiler Collection."
ESVN_REPO_URI="svn://gcc.gnu.org/svn/gcc/branches/gcc-4_6-branch"
SRC_URI="gcj? ( ftp://sourceware.org/pub/java/ecj-4.5.jar )"

LICENSE="GPL-3 LGPL-3 || ( GPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.2"
KEYWORDS=""

SLOT="${GCC_BRANCH_VER}-svn"
IUSE="debug nobootstrap offline"

GCC_SVN="yes"

RDEPEND=""
DEPEND="${RDEPEND}
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	>=${CATEGORY}/binutils-2.18"
PDEPEND="go? ( >=sys-devel/gcc-config-1.5 )"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

src_unpack() {
	export BRANDING_GCC_PKGVERSION="Gentoo SVN"

	[[ -z ${UCLIBC_VER} ]] && [[ ${CTARGET} == *-uclibc* ]] && die "Sorry, this version does not support uClibc"

	# use the offline USE flag to prevent the ebuild from trying to update from
	# the repo.  the current sources will be used instead.
	use offline && ESVN_OFFLINE="yes"

	subversion_src_unpack

	cd "${S}"

	subversion_wc_info
	echo "rev. ${ESVN_WC_REVISION}" > "${S}"/gcc/REVISION

	toolchain_src_unpack

	# drop-in patches
	if ! use vanilla ; then
		if [[ -e ${FILESDIR}/${GCC_RELEASE_VER} ]]; then
			EPATCH_SOURCE="${FILESDIR}/${GCC_RELEASE_VER}" \
			EPATCH_EXCLUDE="${FILESDIR}/${GCC_RELEASE_VER}/exclude" \
			EPATCH_FORCE="yes" EPATCH_SUFFIX="patch" epatch \
			|| die "Failed during patching."
		fi
	fi

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env.patch

	use debug && GCC_CHECKS_LIST="yes"

	# single-stage build for quick patch testing
	if use nobootstrap; then
		GCC_MAKE_TARGET="all"
		EXTRA_ECONF+="--disable-bootstrap"
	fi
}

pkg_preinst() {
	toolchain_pkg_preinst
	subversion_pkg_preinst
}

pkg_postinst() {
	toolchain_pkg_postinst

	einfo "This gcc-4 ebuild is provided for your convenience, and the use"
	einfo "of this compiler is not supported by the Gentoo Developers."
	einfo "Please file bugs related to gcc-4 with upstream developers."
	einfo "Compiler bugs should be filed at http://gcc.gnu.org/bugzilla/"
}
