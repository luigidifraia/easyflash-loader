export PATH := ../win32:$(PATH)

all: tst_loader.crt

tst_loader.crt: loader_and_data
	bin2efcrt $< $@

loader_and_data: loader.bin iffldata
	cat $^ > $@

loader.bin: loader.s config.s main.s asc2ulpet.ct iffltable.s
	acme -o $@ $<

asc2ulpet.ct: asc2ulpet.s
	acme -o $@ $<

iffltable.s: filelist.txt
	./addiffl.sh > $@

clean:
	rm -f iffltable.s asc2ulpet.ct loader.bin iffldata loader_and_data tst_loader.crt
