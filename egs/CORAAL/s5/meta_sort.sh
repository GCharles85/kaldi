#!/usr/bin/bash

#This script contains a generic sorting algorithm. The algorithm sorts based on...
#It checks up to the gender and if possible the part identifier
#but more generally it will identify any delimiters and try to sort with each split portion of the name.
# if it is just a one word title, it just sorts the names
#dont use orig. filename to sort unless the filename is just the orig. file name.
 

#1st: group by filenames in sep. foles/arr using from loc. up to part number. Copy these to a new array/file and delete them from the old array. Run through the old array with this step till it is empty.
     #if what is past the special character is 4 char then we only have originalfnm%bundlepart so sort with that and no need to split up into new arr
     #else do the plan above after 1st
#step 2: indiv. sort each new array/file using the part number.
#step 3: recombine new arrays/files using se number
#step 4: If using arrays, rewrite back to utt2spk file

file='utt2spk'
line_temp=(' ')
number_of_se_groups=$1

sorted=false

if not in CORAAL 
	while read line; do
	
		IFS=' '
		read -a line_arr <<< line
		#line_arr is the line in utt2spk, the uttID and spkID sep. by ' ' 
		line_temp=line_arr[2] #line_temp is everything past the original filename in the spkID
		line_temp=$(line_temp | cut -d'%' -f 2) 
	
		if ${#line_temp[@]}==4 && $sorted==false; #if the only add. data is bundle # and part # then sort numerically and finish
			sort -n utt2spk
			$sorted==true
			break
		fi
	done
fi

#create new array for each se group, sort indiv. then recombine
for (num = 0; num < $1); do
	#make new arr line_newtemp
	current_ID_to_search=$(line_temp | rev | cut-c5- | rev)
	if ($current_ID_to_search in $line_arr); then
		line_newtemp+= $(grep "$current_ID_to_seach" file)
		sed "$current_ID_to_search/d" file
		continue
	fi
done

# indiv sorting each array then combining
final_arr=()
for (num = 0; num < $1); do
	sort -n $line_newtemp
	final_arr=("${final_arr[@]}" "${line_newtemp[@]}")
done

echo $final_arr >> utt2spk
