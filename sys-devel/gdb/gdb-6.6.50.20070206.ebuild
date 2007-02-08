# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-devel/gdb/gdb-6.6.ebuild,v 1.1 2006/12/19 06:30:37 vapier Exp $

inherit flag-o-matic eutils

export CTARGET=${CTARGET:-${CHOST}}
if [[ ${CTARGET} == ${CHOST} ]] ; then
	if [[ ${CATEGORY/cross-} != ${CATEGORY} ]] ; then
		export CTARGET=${CATEGORY/cross-}
	fi
fi

DESCRIPTION="GNU debugger"
HOMEPAGE="http://sources.redhat.com/gdb/"
SRC_URI="ftp://sources.redhat.com/pub/gdb/snapshots/current/gdb-weekly-${PV}.tar.bz2"

LICENSE="GPL-2 LGPL-2"
[[ ${CTARGET} != ${CHOST} ]] \
	&& SLOT="${CTARGET}" \
	|| SLOT="${PV}"
KEYWORDS="-*"
IUSE="nls test"

RDEPEND=">=sys-libs/ncurses-5.2-r2"
DEPEND="${RDEPEND}
	test? ( dev-util/dejagnu )
	nls? ( sys-devel/gettext )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	strip-linguas -u bfd/po opcodes/po
}

src_compile() {
	econf \
		--program-suffix=-${PV} \
		--disable-werror \
		$(use_enable nls) \
		|| die
	emake || die
}

src_test() {
	make check || ewarn "tests failed"
}

src_install() {
	emake \
		DESTDIR="${D}" \
		libdir=/nukeme includedir=/nukeme \
		install || die
	rm -r "${D}"/nukeme || die

	if [[ ${CTARGET} != ${CHOST} ]] ; then
		# Don't install docs when building a cross-gdb
		rm -r "${D}"/usr/share
		return 0
	else
		# Fix collisions with release gdb
		rm -r "${D}"/usr/share/{info,locale}
	fi

	dodoc README
	docinto gdb
	dodoc gdb/CONTRIBUTE gdb/README gdb/MAINTAINERS \
		gdb/NEWS gdb/ChangeLog gdb/PROBLEMS
	docinto sim
	dodoc sim/ChangeLog sim/MAINTAINERS sim/README-HACKING

	dodoc "${WORKDIR}"/extra/gdbinit.sample

	# Remove shared info pages
	rm -f "${D}"/usr/share/info/{annotate,bfd,configure,standards}.info*
}
