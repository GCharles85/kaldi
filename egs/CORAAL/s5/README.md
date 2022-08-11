Guyriano Charles, August 2022

To process CORAAL data and audio with CORAAL scripts:
- install wavfile using pip
- install sequitur-g2p with pip and be sure that the call to g2p.py CORAAL_prepare_dict.sh uses python3 if you are using python3 i.e. "python3 g2p.py".
- In the steps directory, remove run.pl from the parallel directory and place it in the steps directory.
- run getdata.sh script with VLD_files or similar doc passed in. Must contain URLs of transcripts and of CORAAL audio.

