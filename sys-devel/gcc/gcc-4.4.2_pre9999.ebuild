# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

ETYPE="gcc-compiler"
GCC_FILESDIR=${PORTDIR}/sys-devel/gcc/files

inherit toolchain subversion

KEYWORDS=""

DESCRIPTION="The GNU Compiler Collection."
HOMEPAGE="http://gcc.gnu.org/"
ESVN_REPO_URI="svn://gcc.gnu.org/svn/gcc/branches/gcc-4_4-branch"
SRC_URI=""

IUSE="offline debug"

LICENSE="GPL-3 LGPL-3 libgcc libstdc++ gcc-runtime-library-exception-3.1"
SLOT="${GCC_BRANCH_VER}-svn"
SPLIT_SPECS="no"
PRERELEASE="yes"

RDEPEND=">=sys-libs/zlib-1.1.4
	>=sys-devel/gcc-config-1.4
	virtual/libiconv
	>=dev-libs/gmp-4.2.2
	>=dev-libs/mpfr-2.3.0
	graphite? (
		 >=dev-libs/ppl-0.10
		 >=dev-libs/cloog-ppl-0.15.4
	)
	!build? (
		gcj? (
			gtk? (
				x11-libs/libXt
				x11-libs/libX11
				x11-libs/libXtst
				x11-proto/xproto
				x11-proto/xextproto
				>=x11-libs/gtk+-2.2
				x11-libs/pango
			)
			>=media-libs/libart_lgpl-2.1
			app-arch/zip
			app-arch/unzip
		)
		>=sys-libs/ncurses-5.2-r2
		nls? ( sys-devel/gettext )
	)"
DEPEND="${RDEPEND}
	test? ( >=dev-util/dejagnu-1.4.4 >=sys-devel/autogen-5.5.4 )
	>=sys-apps/texinfo-4.8
	>=sys-devel/bison-1.875
	>=sys-devel/flex-2.5.4
	amd64? ( multilib? ( gcj? ( app-emulation/emul-linux-x86-xlibs ) ) )
	>=${CATEGORY}/binutils-2.18"
PDEPEND=">=sys-devel/gcc-config-1.4"

if [[ ${CATEGORY} != cross-* ]] ; then
	DEPEND="${DEPEND} elibc_glibc? ( >=sys-libs/glibc-2.8 )"
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
	echo "built $(date "+%Y%m%d")" > "${S}"/gcc/DATESTAMP

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

	fix_files=""
	for x in contrib/test_summary libstdc++-v3/scripts/check_survey.in ; do
		[[ -e ${x} ]] && fix_files="${fix_files} ${x}"
	done
	ht_fix_file ${fix_files} */configure *.sh */Makefile.in

	if ! is_crosscompile && is_multilib && \
		[[ ( $(tc-arch) == "amd64" || $(tc-arch) == "ppc64" ) && -z ${SKIP_MULTILIB_HACK} ]] ; then
			disgusting_gcc_multilib_HACK || die "multilib hack failed"
	fi

	# >= gcc-4.3 doesn't bundle ecj.jar, so copy it
	if [[ ${GCCMAJOR}.${GCCMINOR} > 4.2 ]] &&
		use gcj ; then
		cp -pPR "${DISTDIR}/ecj-4.3.jar" "${S}/ecj.jar" || die
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

	sed -i 's/use_fixproto=yes/:/' gcc/config.gcc #PR33200

	[[ ${CHOST} == ${CTARGET} ]] && epatch "${GCC_FILESDIR}"/gcc-spec-env.patch
	[[ ${CTARGET} == *-softfloat-* ]] && epatch "${GCC_FILESDIR}"/4.4.0/gcc-4.4.0-softfloat.patch
	epatch "${GCC_FILESDIR}"/4.1.0/gcc-4.1.0-cross-compile.patch

	use debug && EXTRA_ECONF="${EXTRA_ECONF} --enable-checking"
}

# since GCC 4.4 supports parallel make check
# override toolchain.eclass' src_test which forces -j1
src_test() {
	cd "${WORKDIR}"/build
	emake -k check
}

pkg_preinst() {
	toolchain_pkg_preinst
	subversion_pkg_preinst
}
