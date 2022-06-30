#!/usr/bin/bash
#set -o xtrace

#Guyriano Charles, June 2022
#This file moves the audio files to their appropriate test and train folders 
#and creates the utt2spk, wav.scp, text, and spk2gender metadata files. 
#It can also createthe segments file if need be.

cd audio

echo "Gathering audio files from the audio folder..."
#sort the files first
wavs=$(ls )
IFS=$'\n' sortedWavs=($(sort <<< "${wavs[*]}"))
sorted_at=($(sort <<< "$@"))

#move into the train folder and create its meta files

cd ..
cd data/train

#move all the training files and create their utterance IDs 
#while filling in the meta files.
echo "Moving training files to data/train and filling out meta files in data/train..."

for x in $sorted_at; do 
	ran=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)

	ranstr="-"$ran #the random string that will act as the suffix in the 
		       #utterance ID.
	x_tr=${x%.*} #The speaker ID
	ind_pre=${x_tr##*b} #the index of the utterance in its respective wav file
			    # + 1
	ind=$((ind_pre-1))
	ext=".""${x##*.}" #the .wav extension
        
 	uttID=$x_tr$ranstr #the utterance ID
        echo $x_tr ${x:12:1} >> spk2gender
	echo $uttID $x_tr >> utt2spk
	
	#get the correct CORAAL text file and pass that to get_trans.py. 
	#The number after "sub" in the utterance wav filename is the index of the 
	#utterance in its respective text file.
      
	meta=$(find . -type f -name ${x_tr%_sub*}".txt") #remove the sub index
       	#from the file name first to match it to a meta text file
	
	python3 get_trans.py $meta $ind $uttID 0

	#The call below creates the segments file but this may not be necessary
        #since getdata.sh segments the interviews already.
#	python3 get_trans.py $meta $ind $uttID 1

	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp #create the wav.scp file
        cd ..
	cd ..
        mv audio/$x audio/$uttID$ext #rename the file using the utterance ID	
#	mkdir -p data/train/$x_tr && 
	mv audio/$uttID$ext data/train/$x_tr #move the utterance wav file
        #to the train folder
	cd data/train

#done



#move into the test folder
echo "Moving test files into data/test and filling out meta files in data/test..."
cd ..
cd test

#remove the files that are already in train from the wavs array, the wavs array 
#initially contains ALL the utterance wav files. What's left will be moved
#into data/test.

for commFile in $sorted_at; do 				 
	sortedWavs=( "${sortedWavs[@]/$commFile}" )
done

for x in $sortedWavs; do 
	ran=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 6)

	ranstr="-"$ran
	x_tr=${x%.*}
	ind_pre=${x_tr##*b}
	ind=$((ind_pre-1))
	ext=".""${x##*.}"
        
	uttID=$x_tr$ranstr
        echo $x_tr ${x:12:1} >> spk2gender
	echo $uttID $x_tr >> utt2spk
      
	meta=$(find . -type f -name ${x_tr%_sub*}".txt") #remove the sub index from the file name first to match it to a meta text file
	
	python3 get_trans.py $meta $ind $uttID 0

#	python3 get_trans.py $meta $ind $uttID 1

	echo $uttID $(pwd)'/'$uttID$ext >> wav.scp
        cd ..
	cd ..
        mv audio/$x audio/$uttID$ext	
#	mkdir -p data/test/$x_tr &&
	mv audio/$uttID$ext data/test/$x_tr
	cd data/test

done

cd ..
cd ..

mfccdir=${DATA_ROOT}/mfcc
for x in test train; do
	utils/utt2spk_to_spk2utt.pl data/$x/utt2spk > data/$x/spk2utt
	steps/make_mfcc.sh --nj 15500 data/$x exp/make_mfcc/$x $mfccdir
	steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
done




