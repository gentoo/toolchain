#!/bin/bash

# Make sure we only have one instance running at a time.
[[ ${FLOCKER} != $0 ]] && exec env FLOCKER=$0 flock -en $0 -c "$0 $*" || :

set -e
cd "${0%/*}"/..
(
# XXX: Maybe add broken lock/cleanup detection?
svn up -q

doit() {
	./scripts/update-$1
	cd sys-devel/$1

	# Just in case someone else made a commit before we did.
	svn up -q

	# Need the force as newer svn versions (1.7) don't like being
	# given files that already exist.
	svn add -q --force * || :

	[[ -z $(svn st | grep -v '[^AM]') ]]
	svn commit -m "update $1 snapshots"

	cd ../..
}

doit gcc
doit gdb

) >& scripts/cronjob.log
