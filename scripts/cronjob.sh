#!/bin/bash
set -e
cd "${0%/*}"/..
(
svn up -q

./scripts/update-gcc
cd sys-devel/gcc
svn add -q *
svn commit -m 'update gcc snapshots'
cd ../..

./scripts/update-gdb
cd sys-devel/gdb
svn add -q *
svn commit -m 'update gdb snapshots'
cd ../..

) >& scripts/cronjob.log
