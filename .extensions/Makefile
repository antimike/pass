# TODO: Figure out why not every completion script is being linked

CMD_SCRIPTS := $(shell find . -name "*.bash" -executable)
COMPDIR := ~/.local/etc/bash_completion.d

.PHONY: install $(CMD_SCRIPTS)

install: $(CMD_SCRIPTS)
	@export PASSWORD_STORE_ENABLE_EXTENSIONS=true
	@echo "CMD_SCRIPTS = $(CMD_SCRIPTS)"

$(CMD_SCRIPTS): %.bash: pass-%

pass-%:
	@echo "Symlinking completion script '$@' into directory '$(COMPDIR)'"
	@mkdir -p $(COMPDIR) && ln -s $(shell realpath $@) $(COMPDIR)
