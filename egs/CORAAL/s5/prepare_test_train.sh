#!/usr/bin/bash/

#Guyriano Charles, June 2022
#This file moves the audio files to their appropriate test and train folders and creates the utt2spk and wav.scp metadata files.

#Create variables to represent the test and train folders
audio=$(find -name *audio* -type d)
cd data
train=$(find -name *train* -type d)
test=$(find -name *test* -type d)
cd ..

wav=("$(ls audio | *.wav)")

#move into the train folder and create its meta files
cd data/$train
touch utt2spk.txt
touch wav.scp
touch segments.txt
touch text.txt

currdir=$(pwd)
sub='CORAAL'
coraal=0

if $(! grep -q "$sub" <<< "$currdir"); then
	touch spk2gender.txt
	$coraal=1
fi
	

#move all the training files and create their utterance IDs while filling in the meta files.
for x in $@; do 

	ranstr='-'$($RANDOM | md5sum | head -c 6)
	$x = $(cut -f 1 -d '.' $x)
	$ext = "${x##*.}"
	uttID=$x$ranstr
        $coraal=1 && echo $x ${x:12:1} >> spk2gender
	echo $uttID$ext $x >> utt2spk
	
	#get the transcription from the right metafile and set to a var transcr
	#search for a metafile with the ID in its name and using the subnumber to index into that file to the transcription 

	$meta = $(find . type f -name "${x%_sub*}.txt") #remove the sub index from the file name first to match it to a meta text file
	$trans = $(awk 'NR==$ind' $meta)
	$uttID $transcr >> text.txt

	#search for metafile like above and index to appro. segment and store timestamps as segm
	$uttID $uttID >> $segm >> segments.txt

	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp

        mv $audio/$x $audio/$uttID$ext	
	mkdir data/$train/$x && cp $audio/$uttID$ext data/$train/$x

done

#move into the test folder
cd ..
cd data/$test
touch utt2spk.txt
touch wav.scp
touch segments.txt
touch text.txt

#move all the test files and create their utterance IDs while filling in the meta files.
for x in $wav; do

	ranstr=$($RANDOM | md5sum | head -c 6)
	$x = $(cut -f 1 -d '.' $x)
	
	[[ ! -f data/$train/$x ]] || continue
	uttID=$x$ranstr
        $coraal=1 && echo $x ${x:12:1} >> spk2gender
	echo $uttID$ext $x >> utt2spk
	
	#get the transcription from the right metafile and set to a var transcr
	#search for a metafile with the uttid in its name and using the subnumber to index into that file to the transcription 
	$uttID $transcr >> text.txt

	#search for metafile like above and index to appro. segment and store timestamps as segm
	$uttID $uttID >> $segm >> segments.txt

	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp

	mv $audio/$x$ext $audio/$uttID$ext
	mkdir data/$test/$x && cp $audio/$uttID$ext data/$test/$x

done


