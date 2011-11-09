# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

GCC_FILESDIR=${PORTDIR}/sys-devel/gcc/files

inherit multilib subversion toolchain

DESCRIPTION="The GNU Compiler Collection.  Includes C/C++, java compilers, pie+ssp extensions, Haj Ten Brugge runtime bounds checking"
ESVN_REPO_URI="svn://gcc.gnu.org/svn/gcc/branches/gcc-4_5-branch"
SRC_URI="gcj? ( ftp://sourceware.org/pub/java/ecj-4.5.jar )"

IUSE="debug offline"

LICENSE="GPL-3 LGPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1"
KEYWORDS=""
SLOT="${GCC_BRANCH_VER}-svn"
SPLIT_SPECS="no"
PRERELEASE="yes"

RDEPEND=""
DEPEND="${RDEPEND}
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	>=${CATEGORY}/binutils-2.18"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
fi

pkg_setup() {
	if [[ -z ${I_PROMISE_TO_SUPPLY_PATCHES_WITH_BUGS} ]] ; then
		die "Please \`export I_PROMISE_TO_SUPPLY_PATCHES_WITH_BUGS=1\` or define it in your make.conf if you want to use this ebuild.  This is to try and cut down on people filing bugs for a compiler we do not currently support."
	fi
	toolchain_pkg_setup
}

src_unpack() {
	export BRANDING_GCC_PKGVERSION="Gentoo SVN"

	[[ -z ${UCLIBC_VER} ]] && [[ ${CTARGET} == *-uclibc* ]] && die "Sorry, this version does not support uClibc"

	# use the offline USE flag to prevent the ebuild from trying to update from
	# the repo.  the current sources will be used instead.
	use offline && ESVN_OFFLINE="yes"

	subversion_src_unpack

	cd "${S}"

	gcc_version_patch

	subversion_wc_info
	echo ${PV/_/-} > "${S}"/gcc/BASE-VER
	echo "rev. ${ESVN_WC_REVISION}" > "${S}"/gcc/REVISION

	if ! use vanilla ; then
		EPATCH_SOURCE="${FILESDIR}/${GCC_RELEASE_VER}" \
		EPATCH_EXCLUDE="${FILESDIR}/${GCC_RELEASE_VER}/exclude" \
		EPATCH_FORCE="yes" EPATCH_SUFFIX="patch" epatch \
		|| die "Failed during patching."
	fi

	${ETYPE}_src_unpack || die "failed to ${ETYPE}_src_unpack"

	# protoize don't build on FreeBSD, skip it
	## removed in 4.5, bug #270558 --de.
	if [[ ${GCCMAJOR}.${GCCMINOR} < 4.5 ]]; then
		if ! is_crosscompile && ! use elibc_FreeBSD ; then
			# enable protoize / unprotoize
			sed -i -e '/^LANGUAGES =/s:$: proto:' "${S}"/gcc/Makefile.in
		fi
	fi

	setup_multilib_osdirnames

	# >= gcc-4.3 doesn't bundle ecj.jar, so copy it
	if [[ ${GCCMAJOR}.${GCCMINOR} > 4.2 ]] && use gcj ; then
		if tc_version_is_at_least "4.5" ; then
			einfo "Copying ecj-4.5.jar"
			cp -pPR "${DISTDIR}/ecj-4.5.jar" "${S}/ecj.jar" || die
		elif tc_version_is_at_least "4.3" ; then
			einfo "Copying ecj-4.3.jar"
			cp -pPR "${DISTDIR}/ecj-4.3.jar" "${S}/ecj.jar" || die
		fi
	fi

	# Fixup libtool to correctly generate .la files with portage
	cd "${S}"
	elibtoolize --portage --shallow --no-uclibc

	gnuconfig_update

	# update configure files
	local f
	einfo "Fixing misc issues in configure files"
	tc_version_is_at_least 4.1 && epatch "${GCC_FILESDIR}"/gcc-configure-texinfo.patch
	for f in $(grep -l 'autoconf version 2.13' $(find "${S}" -name configure)) ; do
		ebegin "  Updating ${f/${S}\/} [LANG]"
		patch "${f}" "${GCC_FILESDIR}"/gcc-configure-LANG.patch >& "${T}"/configure-patch.log \
			|| eerror "Please file a bug about this"
		eend $?
	done
	sed -i 's|A-Za-z0-9|[:alnum:]|g' "${S}"/gcc/*.awk #215828

	if [[ -x contrib/gcc_update ]] ; then
		einfo "Touching generated files"
		./contrib/gcc_update --touch | \
			while read f ; do
				einfo "  ${f%%...}"
			done
	fi

	disable_multilib_libjava || die "failed to disable multilib java"

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env.patch
	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${GCC_FILESDIR}"/4.4.0/gcc-4.4.0-softfloat.patch
	# Fix cross-compiling
	epatch "${GCC_FILESDIR}"/4.1.0/gcc-4.1.0-cross-compile.patch

	use debug && GCC_CHECKS_LIST="yes"
}

src_install() {
	toolchain_src_install
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
