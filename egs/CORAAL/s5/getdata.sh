#!/usr/bin/bash
#Guyriano Charles, June 2022

#This file downloads CORAAL VLD data and moves it to the VLD_audio directory. It then selects 80% of the files as training data and the rest as test data. The names of the traning data files are sent to VLD_prepare_wav.sh when it is called which places the data into the appropriate folders. It also creates spk2genger, utt2spk, and wav.scp files in both the test and train folders.

#to generalize: pass in links(for audio data and the transcrs) as txt file and get using for loop and the test and train folders

file=$1

echo "Retrieving files from the online DB..."
while read line; do
	wget $line
done 

#process the transcription file and create text file (utt transc) and segments file(utt utt segstart segendr)

#untar the tarball metafile
echo "Extracting audio files..."
$metatar =  $(find . -type f -name "*meta*.tar.gz") 
tar -zxvf $metatar 
rm $metatar

#untar the audio files and extract their utterances
echo "Segmenting audio files..."
filename=' '
for $file in *.tar.gz; do

	[ -f "$file" ] || break
	tar -zxvf $file | $filename
	$meta = $(find . type f -name "$filename.txt") #Grab the appropriate tar file for that interview audio
	
	#also pass the times from the given meta file; $1 is the line number to index to in prepare.sh, $3 is start_time, $5 is end_time
	#move metafile to to train and test
 	./parse_wav.py $filename $(awk '$1 -ne 'Line' && $2 -ne *"int"* && $4 -ne [()<>[]] { print $1, $3, $5 }' $meta) 

done

#to gen: look for a folder with audio in name or pass in audio folder via array as the last element
echo "Moving segments to audio folder..."
mv *sub*.wav audio


cd audio

#randomly select 80% of the audio files to go to the training folder and 20% to go into the test folder
#get count of num of audio files, get 80% of them
echo "Selecting trainning and testing files via 80/20 split"
count=$(ls | wc -l)
count=$count*.80

count=$(echo $count | awk '{printf "%d\n", $1}')

train_files=$(ls . | shuf -n $count)
declare -a train_arr=($train_files)
cd ..

#to gen: append audio folder name to train arr but we dont need to if it looks for it in next script
#call the prepare script
echo "Calling run.sh"
./run.sh ${train_arr[*]}

