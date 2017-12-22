#!/bin/bash
set -eux

DIR=./pay-server

# This is what we'll ship to our users
bazel build main:ruby-typer --config=unsafe -c opt
export PATH=$PATH:"$(pwd)/bazel-bin/main/"

if [ ! -d $DIR ]; then
    echo "$DIR doesn't exist"
    exit 1
fi
cd $DIR

if [ ! -f "../ci/stripe-internal-ruby-typer-pay-server-sha" ]; then
    echo "ci/stripe-internal-ruby-typer-pay-server-sha doesn't exist"
    exit 1
fi
git checkout "$(cat ../ci/stripe-internal-ruby-typer-pay-server-sha)"

# Make sure these specific files are typed
for f in $(cat ../ci/stripe-internal-ruby-typer-pay-server-typechecked); do
    echo "# @typed" >> "$f"
done

RECORD_STATS=
if [ "$GIT_BRANCH" == "master" ] || [ echo "$GIT_BRANCH" | grep -q "^integration-" ]; then
    RECORD_STATS=1
fi

OUT=$(mktemp)
TIMEFILE1=$(mktemp)

/usr/bin/time -v -o "$TIMEFILE1" ./scripts/ruby-types/typecheck 2>&1 | tee "$OUT"
if [ -s "$OUT" ]; then
    exit 1
fi

cat "$TIMEFILE1"

TIME1="$(cat $TIMEFILE1 |grep User |cut -d ' ' -f 4)"
if [ "$RECORD_STATS" ]; then
  veneur-emit -hostport veneur-srv.service.consul:8200 -debug -timing "$TIME1"s -name ruby_typer.payserver.prod_run.seconds
fi



# Run 2: Make sure we don't crash on all of pay-server with ASAN on

cd -
bazel build main:ruby-typer -c opt --config=ci
cd -

TIMEFILE2=$(mktemp)

# Disable leak sanatizer. Does not work in docker
# https://github.com/google/sanitizers/issues/764
ASAN_OPTIONS=detect_leaks=0 LSAN_OPTIONS=verbosity=1:log_threads=1  /usr/bin/time -v -o "$TIMEFILE2" ./scripts/ruby-types/typecheck --quiet --typed=always --statsd-host=veneur-srv.service.consul --statsd-prefix=ruby_typer.payserver --counters

cat "$TIMEFILE2"

TIME2="$(cat $TIMEFILE2 |grep User |cut -d ' ' -f 4)"
if [ "$RECORD_STATS" ]; then
  veneur-emit -hostport veneur-srv.service.consul:8200 -debug -timing "$TIME2"s -name ruby_typer.payserver.full_run.seconds
fi
