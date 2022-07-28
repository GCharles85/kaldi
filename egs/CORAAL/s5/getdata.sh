#!/usr/bin/bash
#Guyriano Charles, June 2022

#This file downloads CORAAL VLD data and moves it to the VLD_audio directory. It then selects 80% of the files as training data and the rest as test data. The names of the training data files are sent to VLD_prepare_wav.sh when it is called which places the data into the appropriate folders. It also creates spk2genger, utt2spk, and wav.scp files in both the test and train folders.

#Pass in links(for audio data and the transcriptions) as txt file 

source path.sh
source cmd.sh

for x in train test; do
	mkdir -p data/$x
done

if [ "$1" == *.txt ]; then
	echo "File containing links to data must not be text file" && exit 1
fi

echo "Retrieving files from the online DB..."
#wget -i $1 

#untar the tarball textfile
#echo "Extracting textfiles..."
#text_tar=$(find . -type f -name "*textfile*.tar.gz") 
#tar -zxvf $text_tar && rm $text_tar

#untar the audio files

#tar_gz=$(find . -type f -name "*.tar.gz")
#for file in $tar_gz; do

#	[ -f "$file" ] || break
#	tar -zxvf $file 
#	rm $file

#done
 
#nonnecfiles=$(find . -type f -name "._*") #Grab the appropriate misc. tar file for that interview audio and remove it.
#rm -r $nonnecfiles

echo "Segmenting audio files..."

for text in *.txt; do

	$(sed -i "1d" $text) #remove the column names from the text and only leave the actual data

        #extract all lines from the text files that are not the interviewer and that do not contain action descriptors such as (pause)
	$(awk -F"[][(*)<*>/*/]" '$0 !~ /'int'/ { print $3, $NF }' $text > awk_tout.txt)
        $(awk '$0 ~ /'se'/ { print $1, $3, $NF }' awk_tout.txt > awk_out.txt) 
	for i in *.wav; do
		if [[ ${i##*.}==${text##*.} ]]; then
			python3 parse_wav.py "$i" "awk_out.txt" #segment the lines from above out of the interview wav file
			mv ./*sub*.wav ./audio #the segments have a descriptor "sub" in their filename, moves these to the audio folder.
		fi
	done

	cp $text data/train #move the text file to both the train and test folders
        mv $text data/test
done


cd audio

#randomly select 80% of the audio files to go to the training folder and 20% to go into the test folder
#get count of num of audio files, get 80% of them
echo "Selecting training and testing files via 80/20 split"
count=$(ls *.wav | wc -l)
count="$(($count*4/5))"


train_files=$(ls *.wav | shuf -n $count)
declare -a train_arr=($train_files) #the array train_arr contains utterance wav files to be moved into the train folder.

#call the prepare script
echo "Calling run.sh"
cd ..
./run.sh ${train_arr[*]}

