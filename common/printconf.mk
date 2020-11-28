userconf:
	$(call echo,"USER_CC===$(CFLAGS)")
	$(call echo,"USER_CX===$(CPPFLAGS)")
	$(call echo,"USER_LD===$(LDFLAGS)")

elfconf:
	$(call echo,"ELF_CC===$(CFLAGS)")
	$(call echo,"ELF_CX===$(CPPFLAGS)")
	$(call echo,"ELF_LD===$(LDFLAGS)")
