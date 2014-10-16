LINK_DIR =  ../masm32/bin


nop: hashsinc
	echo "#Config"> config.inc
	cat cust_config.inc >> config.inc
	yasm -f win32 -m x86 nop.asm -o nop.obj
	wine $(LINK_DIR)/polink /ENTRY:start /SUBSYSTEM:WINDOWS $(LINK_DIR)/../lib/user32.lib $(LINK_DIR)/../lib/kernel32.lib nop.obj /verbose 2>/dev/null

all: nop


clean:
	-rm -f nop.obj cust_config.inc nop.exe hashs.inc config.inc

# DLL and Function hash generator
hashsinc: hashname.py
	./hashname.py


