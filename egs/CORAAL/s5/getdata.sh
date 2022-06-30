#!/usr/bin/bash
#Guyriano Charles, June 2022

#This file downloads CORAAL VLD data and moves it to the VLD_audio directory. It then selects 80% of the files as training data and the rest as test data. The names of the training data files are sent to VLD_prepare_wav.sh when it is called which places the data into the appropriate folders. It also creates spk2genger, utt2spk, and wav.scp files in both the test and train folders.

#Pass in links(for audio data and the transcriptions) as txt file 

source path.sh
source cmd.sh

echo "Retrieving files from the online DB..."
wget -i $1 

#untar the tarball textfile
echo "Extracting textfiles..."
text_tar=$(find . -type f -name "*textfile*.tar.gz") 
tar -zxvf $text_tar && rm $text_tar

#untar the audio files

tar_gz=$(find . -type f -name "*.tar.gz")
for file in $tar_gz; do

	[ -f "$file" ] || break
	tar -zxvf $file 
	rm $file

done

wavs=$(find . -type f -name "*.wav")

nonnecfiles=$(find . -type f -name "._*") #Grab the appropriate misc. tar file for that interview audio and remove it.
rm -r $nonnecfiles
texts=$(find . -maxdepth 1 -type f -name "*.txt")

echo "Segmenting audio files..."


for text wav in texts wavs; do
	$(sed -i "1d" $text) #remove the column names from the text and only leave the actual data
	$(awk '$2 !~ /'int'/ && $4 !~ //[(<[]/ { print NR, $3, $NF }' $text > awk_out.txt) #extract all lines from the text files that are not the interviewer and that do not contain action descriptors such as (pause)
	python3 parse_wav.py $wav "awk_out.txt" #segment the lines from above out of the interview wav file
        cp $text data/train #move the text file to both the train and test folders
        mv $text data/test
done

echo "Moving segments to audio folder..."
mv *sub*.wav audio #the segments have a descriptor "sub" in their filename, moves these to the audio folder.


cd audio

#randomly select 80% of the audio files to go to the training folder and 20% to go into the test folder
#get count of num of audio files, get 80% of them
echo "Selecting training and testing files via 80/20 split"
count=$(ls | wc -l)
count="$(($count*4/5))"


train_files=$(ls . | shuf -n $count)
declare -a train_arr=($train_files) #the array train_arr contains utterance wav files to be moved into the train folder.

#call the prepare script
echo "Calling run.sh"
cd ..
./run.sh ${train_arr[*]}

