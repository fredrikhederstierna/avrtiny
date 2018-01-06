
# To setup environment in Linux, package needed:
# sudo apt-get install avrdude avr-libc binutils-avr gcc-avr gdb-avr srecord simulavr

TARGET = main

AVRDUDE = sudo avrdude

# 4MHz for accurate baudrate timing
AVR_FREQ = 4000000
AVR_TYPE = attiny25

# avrdude settings
BAUD = 19200
PRG_DEV  = usb
PRG_TYPE = avrisp2

WARNINGS = -Wall -W -Werror -Wextra
OPTIMIZATION = -Os
CFLAGS = -g -DF_CPU=$(AVR_FREQ) $(WARNINGS) $(OPTIMIZATION)

MEM_TYPES = calibration eeprom efuse flash fuse hfuse lfuse lock signature
# Not defined for tiny25:
# application apptable boot prodsig usersig

.PHONY: backup clean dis dumpelf eeprom elf flash fuses help hex object program

all: object elf hex

clean:
	rm $(TARGET).elf $(TARGET).eeprom.hex $(TARGET).fuses.hex $(TARGET).lfuse.hex $(TARGET).hfuse.hex $(TARGET).efuse.hex $(TARGET).flash.hex $(TARGET).o $(TARGET).lst
	date

object:
	avr-gcc $(CFLAGS) -mmcu=$(AVR_TYPE) -Wa,-ahlmns=$(TARGET).lst -c -o $(TARGET).o $(TARGET).c

elf: object
	avr-gcc $(CFLAGS) -mmcu=$(AVR_TYPE) -o $(TARGET).elf $(TARGET).o
	chmod a-x $(TARGET).elf 2>&1

hex: elf
	avr-objcopy -j .text -j .data -O ihex $(TARGET).elf $(TARGET).flash.hex
	avr-objcopy -j .eeprom --set-section-flags=.eeprom="alloc,load" --change-section-lma .eeprom=0 -O ihex $(TARGET).elf $(TARGET).eeprom.hex
	avr-objcopy -j .fuse -O ihex $(TARGET).elf $(TARGET).fuses.hex --change-section-lma .fuse=0
	srec_cat $(TARGET).fuses.hex -Intel -crop 0x00 0x01 -offset  0x00 -O $(TARGET).lfuse.hex -Intel
	srec_cat $(TARGET).fuses.hex -Intel -crop 0x01 0x02 -offset -0x01 -O $(TARGET).hfuse.hex -Intel
	srec_cat $(TARGET).fuses.hex -Intel -crop 0x02 0x03 -offset -0x02 -O $(TARGET).efuse.hex -Intel

dis:
	avr-objdump -s -j .fuse $(TARGET).elf
	avr-objdump -C -d $(TARGET).elf 2>&1

eeprom: hex
#$(AVRDUDE) -p$(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U eeprom:w:$(TARGET).eeprom.hex
	date

fuses: hex
	$(AVRDUDE) -p$(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U lfuse:w:$(TARGET).lfuse.hex
#$(AVRDUDE) -p$(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U hfuse:w:$(TARGET).hfuse.hex
#$(AVRDUDE) -p$(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U efuse:w:$(TARGET).efuse.hex
	date

dumpelf: elf
	avr-objdump -s -h $(TARGET).elf

program: flash eeprom fuses

flash: hex
	$(AVRDUDE) -p$(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U flash:w:$(TARGET).flash.hex
	date

backup:
	@for memory in $(MEM_TYPES); do \
		$(AVRDUDE) -p $(AVR_TYPE) -c$(PRG_TYPE) -P$(PRG_DEV) -b$(BAUD) -v -U $$memory:r:./$(AVR_TYPE).$$memory.hex:i; \
	done
