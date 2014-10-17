#!/bin/bash

techniques=( NOSB_RDTSCLOOP NOSB_INTELONLY NOSB_NOL1ICACHE NOSB_HYPERBIT NOSB_UNSLEAF NOSB_PEBCOUNT NOSB_RENAMED NOSB_ROGUEDLL NOSB_HOOKPROC NOSB_HYPSTR )

mkdir out
make clean
make 
cp nop.exe out/NOP_NOTHING.exe

for i in "${techniques[@]}"
do
	echo "---> Compiling $i"
	make clean
	echo "%define $i True" >  cust_config.inc
	make 
        cp nop.exe ./out/NOP_$i.exe
done

chmod -x *.exe
echo " " 
echo " " 
echo " " 
echo "---------------------------------------"
ls -l out/*.exe
echo " " 
md5sum out/*.exe

