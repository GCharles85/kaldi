#!/usr/bin/env bash

# Copyright 2012  Vassil Panayotov
#           2014  Johns Hopkins University (author: Daniel Povey)
# Apache 2.0

# Makes train/test splits

. ./path.sh

echo "=== Starting initial CORAAL data preparation ..."

echo "--- Making test/train data split ..."

# The number of speakers in the test set
nspk_test=1000

. utils/parse_options.sh

if [ $# != 1 ]; then
  echo "Usage: $0 <data-directory>";
  exit 1;
fi

#command -v flac >/dev/null 2>&1 ||\
# { echo "FLAC decompressor needed but not found"'!' ; exit 1; }

DATA=$1

locdata=data/local
loctmp=$locdata/tmp
rm -rf $loctmp >/dev/null 2>&1
mkdir -p $locdata
mkdir -p $loctmp
# The "sed" expression below is quite messy because some of the directrory
# names don't follow the "speaker-YYYYMMDD-<random_3letter_suffix>" convention.
# The ";tx;d;:x" part of the expression is to filter out the directories,
# not matched by the expression

find $DATA/ -mindepth 1 -maxdepth 1 |\
# perl -ane ' s:.*/((.+)\-[0-9]{8,10}[a-z]*([_\-].*)?):$2: && print; ' | \
sort -u > $loctmp/speakers_all.txt

nspk_all=$(wc -l <$loctmp/speakers_all.txt)
if [ "$nspk_test" -ge "$nspk_all" ]; then
  echo "${nspk_test} test speakers requested, but there are only ${nspk_all} speakers in total!"
  exit 1;
fi

echo $2 > $loctmp/speakers_test.txt

echo $1 > speakers_train.txt

wc -l $loctmp/speakers_all.txt
wc -l $loctmp/speakers_{train,test}.txt

logdir=exp/data_prep
mkdir -p $logdir
echo -n > $logdir/make_trans.log
rm ${locdata}/spk2gender 2>/dev/null

trans_err=$(wc -l <${logdir}/make_trans.log)
if [ "${trans_err}" -ge 1 ]; then
  echo -n "$trans_err errors detected in the transcripts."
  echo " Check ${logdir}/make_trans.log for details!" 
fi

#awk '{spk[$1]=$2;} END{for (s in spk) print s " " spk[s]}' \
#  $locdata/spk2gender.tmp | sort -k1 > $locdata/spk2gender

echo "*** Initial CORAAL data preparation finished!"
