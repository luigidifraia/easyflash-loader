#!/bin/bash

set +o histexpand

offst=0
rm -f iffldata

print_snippet () {
  file=$1
  sz=$2
  bank=$3
  strt=$4
  echo "; Inserting $file ($sz)"
  printf  "        !byte $%x\n" $bank
  printf  "        !word $%x\n" $strt
  echo -e "        !byte 0\n"
}

while IFS=" " read -r file || [[ -n $file ]]; do
  sz=$(stat --printf="%s" "$file")
  bank=$(( 1 + offst / 16384 ))
  strt=$(( offst % 16384 ))
  strt=$(( strt + 32768 ))
  print_snippet $file $sz $bank $strt
  offst=$(( offst + sz ))
  cat $file >> iffldata
done < filelist.txt

# Terminator
bank=$(( 1 + offst / 16384 ))
strt=$(( offst % 16384 ))
strt=$(( strt + 32768 ))
print_snippet "terminator" 0 $bank $strt

sz=$(stat --printf="%s" "iffldata")
pad=$(( $sz / 16384 ))
pad=$(( $pad + 1))
pad=$(( $pad * 16384))
pad=$(( $pad - $sz))
dd if=/dev/zero bs=1 count=$pad | tr "\000" "\377" >> iffldata
