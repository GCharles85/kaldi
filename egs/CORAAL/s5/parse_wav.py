#!/usr/bin/python3
#Guyriano Charles
#This script extracts segments out of an audio file

import wavfile
import sys

sampRate=44100

def main():
    file = open(sys.argv[2], 'r')
    lines = file.readlines()

    for line in lines:
         line = line.strip().split()
         print(line)
         f = wavfile.open(sys.argv[1], 'r') #creates wavfile object
         offset = round(float(line[1]))*sampRate
         f.seek(offset, 0) #sets the pointer of the object from to some frame 

         start = float(line[1]) #the start time of the segment to be extracted
         numSamples = (float(line[2]) - start)*sampRate #how long the segment is in units of sample
    
         reading = f.read(round(numSamples)) #extracts the segment 

         if line[0].isdigit():
            newWavFile = sys.argv[1][:-4]+'_sub'+line[0]+'.wav'
            wavfile.write(newWavFile, reading) #writes a new audio file containing the segment

    

main()
