#!/usr/bin/bash

#Guyriano Charles, June 2022
#This file moves the audio files to their appropriate test and train folders 
#and creates the utt2spk, wav.scp, text, and spk2gender metadata files. 
#It can also createthe segments file if need be.

source path.sh
source cmd.sh

# The number of parallel jobs to be started for some parts of the recipe
# Make sure you have enough resources(CPUs and RAM) to accomodate this number of jobs
njobs=3

# Test-time language model order
lm_order=2

# Word position dependent phones?
pos_dep_phones=true

# The directory below will be used to link to a subset of the user directories
# based on various criteria(currently just speaker's accent)
DATA=${DATA_ROOT}

# The user of this script could change some of the above parameters. Example:
# /bin/bash run.sh --pos-dep-phones false
. utils/parse_options.sh || exit 1

cd audio

echo "Gathering audio files from the audio folder..."
#sort the files first
wavs=$(ls *.wav)
trains=( "$@" )

# The number of speakers in the test set
nspk_test=1000

locdata=${KALDI_ROOT}/egs/CORAAL/s5/data/local
loc=${KALDI_ROOT}/egs/CORAAL/s5/local
loctmp=$locdata/tmp
rm -rf $loctmp >/dev/null 2>&1
mkdir -p $locdata
mkdir -p $loctmp

printf '%s\n' ${wavs[*]} > $loctmp/allSpeakers.txt
printf '%s\n' ${trains[*]} > $loctmp/trainSet.txt

printf '%s\n' $(sort $loctmp/allSpeakers.txt | uniq -u) > $loctmp/speakers_all.txt
printf '%s\n' $(sort $loctmp/trainSet.txt | uniq -u) > $loctmp/speakers_train.txt

printf '%s\n' $(comm -13 $loctmp/speakers_train.txt $loctmp/speakers_all.txt |sort | uniq -u) > $loctmp/speakers_test.txt

nspk_all=$(wc -l <$loctmp/speakers_all.txt)

if [ "$nspk_test" -ge "$nspk_all" ]; then
  echo "${nspk_test} test speakers requested, but there are only ${nspk_all} speakers in total!"
  exit 1;
fi

#move into the train folder and create its meta files
cd ..
cd data/train

#move all the training files and create their utterance IDs 
#while filling in the meta files.
echo "Moving training files to data/train and filling out meta files in data/train..."

while read -r line; do	
	ran=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)

	ranstr="-"$ran #the random string that will act as the suffix in the 
		       #utterance ID.
        spkID=${line%.*} #The speaker ID
	
	ind_pre=${spkID##*b} #Index of utterance in respective wav file + 1 
	
	ind=$((ind_pre-1))
        	
	ext=".""${line##*.}" #the .wav extension
       	
 	uttID=$spkID$ranstr #the utterance ID
        echo $spkID ${line:12:1} >> spk2gender
	echo $uttID $spkID >> utt2spk
	
	#get the correct CORAAL text file and pass that to get_trans.py. 
	#The number after "sub" in the utterance wav filename is the index of the 
	#utterance in its respective text file.
      
	meta=$(find . -type f -name ${spkID%_sub*}".txt") || exit 1 #remove the sub index
      	#from the file name first to match it to a meta text file
	
	python3 $loc/get_trans.py $meta $ind $uttID 0
	
	#The call below creates the segments file but this may not be necessary
        #since getdata.sh segments the interviews already.
#	python3 get_trans.py $meta $ind $uttID 1
        
	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp #create the wav.scp file

        cd ..
	cd ..
        mv audio/$line audio/$uttID$ext || exit 1 #rename the file using the utterance ID	
	#mkdir -p data/train/$x_tr && 
	mv audio/$uttID$ext data/train #move the utterance wav file
        #to the train folder
	cd data/train

done < $loctmp/speakers_train.txt

cp wav.scp $locdata/train_wav.txt || exit 1
cp text $locdata/train_trans.txt

#move into the test folder
echo "Moving test files into data/test and filling out meta files in data/test..."
cd ..
cd test

#remove the files that are already in train from the wavs array, the wavs array 
#initially contains ALL the utterance wav files. What's left will be moved
#into data/test.

while read -r line; do 
	ran=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)

	ranstr="-"$ran
	spkID=${line%.*}
	
	ind_pre=${spkID##*b}

	ind=$((ind_pre-1))
	
	ext=".""${line##*.}"
        
	uttID=$spkID$ranstr
        echo $spkID ${line:12:1} >> spk2gender
	echo $uttID $spkID >> utt2spk
      
	meta=$(find . -type f -name ${spkID%_sub*}".txt") #remove the sub index from the file name first to match it to a meta text file
	
	python3 $loc/get_trans.py $meta $ind $uttID 0

	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp

        cd ..
	cd ..
        mv audio/$line audio/$uttID$ext || exit 1
	mkdir -p data/test/$x_tr &&
	mv audio/$uttID$ext data/test
	cd data/test

done < $loctmp/speakers_test.txt

cp wav.scp $locdata/test_wav.txt
cp text $locdata/test_trans.txt

cd ..
cd ..

echo "done up to ARPA prep"

# Prepare ARPA LM and vocabulary using SRILM
local/CORAAL_prepare_lm.sh --order ${lm_order} || exit 1

# Prepare the lexicon and various phone lists
# Pronunciations for OOV words are obtained using a pre-trained Sequitur model
local/CORAAL_prepare_dict.sh || exit 1

#Prepare data/lang and data/local/lang directories
utils/prepare_lang.sh --position-dependent-phones $pos_dep_phones \data/local/dict "!SIL" data/local/lang data/lang || exit 1

# Prepare G.fst and data/{train,test} directories
local/CORAAL_format_data.sh || exit 1



mfccdir=${DATA_ROOT}/mfcc
for x in test train; do
	utils/utt2spk_to_spk2utt.pl data/$x/utt2spk > data/$x/spk2utt
	steps/make_mfcc.sh --nj $njobs data/$x exp/make_mfcc/$x $mfccdir
	steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done

# Train monophone models on a subset of the data
utils/subset_data_dir.sh data/train 100 data/train.1k  || exit 1;
steps/train_mono.sh --nj $njobs --cmd "$train_cmd" data/train.1k data/lang exp/mono  || exit 1;

# Monophone decoding
utils/mkgraph.sh data/lang_test exp/mono exp/mono/graph || exit 1
# note: local/decode.sh calls the command line once for each
# test, and afterwards averages the WERs into (in this case
# exp/mono/decode/)
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \ exp/mono/graph data/test exp/mono/decode

# Get alignments from monophone system.
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \  data/train data/lang exp/mono exp/mono_ali || exit 1;

# train tri1 [first triphone pass]
steps/train_deltas.sh --cmd "$train_cmd" \ 2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1;

# decode tri1
utils/mkgraph.sh data/lang_test exp/tri1 exp/tri1/graph || exit 1;
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \ exp/tri1/graph data/test exp/tri1/decode

draw-tree data/lang/phones.txt exp/tri1/tree | dot -Tps -Gsize=8,10.5 | ps2pdf - tree.pdf

# align tri1
steps/align_si.sh --nj $njobs --cmd "$train_cmd" \  --use-graphs true data/train data/lang exp/tri1 exp/tri1_ali || exit 1;

# train tri2a [delta+delta-deltas]
steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 \  data/train data/lang exp/tri1_ali exp/tri2a || exit 1;

# decode tri2a
utils/mkgraph.sh data/lang_test exp/tri2a exp/tri2a/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \ exp/tri2a/graph data/test exp/tri2a/decode

# train and decode tri2b [LDA+MLLT]
steps/train_lda_mllt.sh --cmd "$train_cmd" 2000 11000 \ data/train data/lang exp/tri1_ali exp/tri2b || exit 1;
utils/mkgraph.sh data/lang_test exp/tri2b exp/tri2b/graph
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \  exp/tri2b/graph data/test exp/tri2b/decode

# Align all data with LDA+MLLT system (tri2b)
steps/align_si.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \ data/train data/lang exp/tri2b exp/tri2b_ali || exit 1;

#  Do MMI on top of LDA+MLLT.
steps/make_denlats.sh --nj $njobs --cmd "$train_cmd" \  data/train data/lang exp/tri2b exp/tri2b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \  exp/tri2b/graph data/test exp/tri2b_mmi/decode_it4
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \ exp/tri2b/graph data/test exp/tri2b_mmi/decode_it3

# Do the same with boosting.
steps/train_mmi.sh --boost 0.05 data/train data/lang \ exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mmi_b0.05 || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \  exp/tri2b/graph data/test exp/tri2b_mmi_b0.05/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \  exp/tri2b/graph data/test exp/tri2b_mmi_b0.05/decode_it3 || exit 1;

# Do MPE.
steps/train_mpe.sh data/train data/lang exp/tri2b_ali exp/tri2b_denlats exp/tri2b_mpe || exit 1;
steps/decode.sh --config conf/decode.config --iter 4 --nj $njobs --cmd "$decode_cmd" \  exp/tri2b/graph data/test exp/tri2b_mpe/decode_it4 || exit 1;
steps/decode.sh --config conf/decode.config --iter 3 --nj $njobs --cmd "$decode_cmd" \ exp/tri2b/graph data/test exp/tri2b_mpe/decode_it3 || exit 1;


## Do LDA+MLLT+SAT, and decode.
steps/train_sat.sh 2000 11000 data/train data/lang exp/tri2b_ali exp/tri3b || exit 1;
utils/mkgraph.sh data/lang_test exp/tri3b exp/tri3b/graph || exit 1;
steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \  exp/tri3b/graph data/test exp/tri3b/decode || exit 1;


# Align all data with LDA+MLLT+SAT system (tri3b)
steps/align_fmllr.sh --nj $njobs --cmd "$train_cmd" --use-graphs true \ data/train data/lang exp/tri3b exp/tri3b_ali || exit 1;

## MMI on top of tri3b (i.e. LDA+MLLT+SAT+MMI)
steps/make_denlats.sh --config conf/decode.config \  --nj $njobs --cmd "$train_cmd" --transform-dir exp/tri3b_ali \
data/train data/lang exp/tri3b exp/tri3b_denlats || exit 1;
steps/train_mmi.sh data/train data/lang exp/tri3b_ali exp/tri3b_denlats exp/tri3b_mmi || exit 1;

steps/decode_fmllr.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \ --alignment-model exp/tri3b/final.alimdl --adapt-model exp/tri3b/final.mdl \ exp/tri3b/graph data/test exp/tri3b_mmi/decode || exit 1;

# Do a decoding that uses the exp/tri3b/decode directory to get transforms from.
steps/decode.sh --config conf/decode.config --nj $njobs --cmd "$decode_cmd" \ --transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_mmi/decode2 || exit 1;


#first, train UBM for fMMI experiments.
steps/train_diag_ubm.sh --silence-weight 0.5 --nj $njobs --cmd "$train_cmd" \ 250 data/train data/lang exp/tri3b_ali exp/dubm3b

# Next, various fMMI+MMI configurations.
steps/train_mmi_fmmi.sh --learning-rate 0.0025 \--boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \exp/tri3b_fmmi_b || exit 1;

for iter in 3 4 5 6 7 8; do
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \	
		--transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_b/decode_it$iter &
done

steps/train_mmi_fmmi.sh --learning-rate 0.001 \--boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \ exp/tri3b_fmmi_c || exit 1;

for iter in 3 4 5 6 7 8; do
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \ 
		--transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_c/decode_it$iter &
done

# for indirect one, use twice the learning rate.
steps/train_mmi_fmmi_indirect.sh --learning-rate 0.002 --schedule "fmmi fmmi fmmi fmmi mmi mmi mmi mmi" \ --boost 0.1 --cmd "$train_cmd" data/train data/lang exp/tri3b_ali exp/dubm3b exp/tri3b_denlats \ exp/tri3b_fmmi_d || exit 1;

for iter in 3 4 5 6 7 8; do
	steps/decode_fmmi.sh --nj $njobs --config conf/decode.config --cmd "$decode_cmd" --iter $iter \
	--transform-dir exp/tri3b/decode  exp/tri3b/graph data/test exp/tri3b_fmmi_d/decode_it$iter &
done

local/run_sgmm2.sh --nj $njobs



