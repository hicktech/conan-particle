# Create a bin file from ELF file

ifeq ("$(v)","1")
ECHO=echo
VERBOSE=
VERBOSE_REDIRECT=
else
ECHO = true
VERBOSE=@
VERBOSE_REDIRECT= > /dev/null 2>&1
endif

filesize=`stat -c %s $1`
SHA_256 = shasum -a 256
XXD = /usr/bin/xxd
CRC = crc32
CRC_LEN = 4
CRC_BLOCK_LEN = 38
DEFAULT_SHA_256 = 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20
MOD_INFO_SUFFIX_LEN ?= 2800
MOD_INFO_SUFFIX = $(DEFAULT_SHA_256)$(MOD_INFO_SUFFIX_LEN)
CRC_BLOCK_CONTENTS = $(MOD_INFO_SUFFIX)78563412
OBJCOPY = /usr/local/gcc-arm/bin/arm-none-eabi-objcopy

src :
	$(call echo,'Invoking: ARM GNU Create Flash Image')
	$(VERBOSE)$(OBJCOPY) -O binary $(ELF) $< $@.pre_crc
	$(VERBOSE)if [ -s $@.pre_crc ]; then \
	head -c $$(($(call filesize,$@.pre_crc) - $(CRC_BLOCK_LEN))) $@.pre_crc > $@.no_crc && \
	tail -c $(CRC_BLOCK_LEN) $@.pre_crc > $@.crc_block && \
	test "$(CRC_BLOCK_CONTENTS)" = `xxd -p -c 500 $@.crc_block` && \
	$(SHA_256) $@.no_crc | cut -c 1-65 | $(XXD) -r -p | dd bs=1 of=$@.pre_crc seek=$$(($(call filesize,$@.pre_crc) - $(CRC_BLOCK_LEN))) conv=notrunc $(VERBOSE_REDIRECT) && \
	head -c $$(($(call filesize,$@.pre_crc) - $(CRC_LEN))) $@.pre_crc > $@.no_crc && \
	 $(CRC) $@.no_crc | cut -c 1-10 | $(XXD) -r -p | dd bs=1 of=$@.pre_crc seek=$$(($(call filesize,$@.pre_crc) - $(CRC_LEN))) conv=notrunc $(VERBOSE_REDIRECT);\
	fi
	$(VERBOSE)[ ! -f $@ ] || rm $@
	$(VERBOSE)mv $@.pre_crc $@.bin
	$(call echo,)
