#!/bin/bash -eu
# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
################################################################################

# build project
rm -rf build

./configure
make njs

# build fuzzers
# e.g.
$CC $CFLAGS -Inxt -Ibuild -Injs -c \
    $SRC/njs_process_script_fuzzer.c -o build/njs_process_script_fuzzer.o

$CXX $CXXFLAGS build/njs_process_script_fuzzer.o -o $OUT/njs_process_script_fuzzer \
    $LIB_FUZZING_ENGINE build/libnxt.a build/libnjs.a -lm -lpcre -lreadline

SEED_CORPUS_PATH=$OUT/njs_process_script_fuzzer_seed_corpus
mkdir -p $SEED_CORPUS_PATH

set +x
cat njs/test/njs_interactive_test.c njs/test/njs_unit_test.c \
    | egrep -o '".*"' | awk '{print substr($0,2,length($0)-2)}' | sort | uniq \
    | while IFS= read -r line; do
      echo $line > $SEED_CORPUS_PATH/$(echo $line | sha1sum | awk '{ print $1 }');
    done
set -x

zip -q $SEED_CORPUS_PATH.zip $SEED_CORPUS_PATH
rm -rf $SEED_CORPUS_PATH

