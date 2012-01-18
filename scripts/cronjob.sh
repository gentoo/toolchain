#!/bin/bash
set -e
cd "${0%/*}"/..
(
svn up -q

doit() {
	./scripts/update-$1
	cd sys-devel/$1
	svn add -q * || :
	[[ -z $(svn st | grep -v '[^AM]') ]]
	svn commit -m "update $1 snapshots"
	cd ../..
}

doit gcc
doit gdb

) >& scripts/cronjob.log
