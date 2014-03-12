#!/bin/bash

# Make sure we only have one instance running at a time.
[[ ${FLOCKER} != $0 ]] && exec env FLOCKER=$0 flock -en $0 -c "$0 $*" || :
NCPUS=$(getconf _NPROCESSORS_ONLN)

set -e
cd "${0%/*}"/..

svn_commit() {
	# Just in case someone else made a commit before we did.
	svn up -q

	# Need the force as newer svn versions (1.7) don't like being
	# given files that already exist.
	svn add -q --force * || :

	local st=$(svn st .)

	local d=$(echo "${st}" | awk '$1 ~ /^[!?]/ { print $NF }')
	if [[ -n ${d} ]] ; then
		svn rm ${d}
	fi

	if [[ -z $(svn st . | grep -v '[^AM]') ]] ; then
		svn commit -m "$1" .
	fi
}

doit() {
	./scripts/update-$1
	cd sys-devel/$1
	svn_commit "update $1 snapshots"
	cd ../..
}

main() {
	(
	# XXX: Maybe add broken lock/cleanup detection?
	svn upgrade || :
	svn revert -R .
	svn up -q
	doit gcc
	doit gdb

	egencache --repo=toolchain --update --portdir-overlay="${PWD}" -j ${NCPUS:-1}
	cd metadata
	svn_commit "update metadata"
	) >& scripts/cronjob.log
}
main "$@"
