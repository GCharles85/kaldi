#Guyriano Charles
# This file extracts segments out of an audio fole

import wavfile
import sys.argv as args

def main(self, args[]):
    for el in args[2]{

         f = wavfile.open(args[1], 'r') #creates wavfile object
         f.seek(round(el[0]), 0) #sets the pointer of the object from to some frame 

         start = el[0] #the start time of the segment to be extracted
         numsamples = (el[1] - start)*sampRate #how long the segment is in units of sample
    
         reading = f.read(numSamples) #extracts the segment 
         newWavFile = args[1]+'sub'+str(el[2])
    
         wavfile.write(newWavFile, reading) #writes a new audio file containing the segment

    }

main(arg[])
