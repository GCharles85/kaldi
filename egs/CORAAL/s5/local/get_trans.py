#!/usr/bin/python3
#Guyriano Charles, June 2022
#This script extracts segments out of an audio file

import sys
import re

def main():
    file = open(sys.argv[1], 'r')
    lines = file.readlines()
    
    if sys.argv[4]=='0':
        aline = lines[int(sys.argv[2])].split('\t')[3]
        line = re.sub(r'[^\w\s]', '', aline)

        file1 = open('text', 'a')
        file1.write(sys.argv[3]+" "+line+"\n")
    else:
        aline = lines[int(sys.argv[2])].split('\t')
        start=aline[2]
        end=aline[4]

        file1 = open('segments', 'a')
        file1.write(sys.argv[3]+" "+sys.argv[3]+" "+start+" "+end)

main()
