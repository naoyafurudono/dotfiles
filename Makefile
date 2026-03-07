.PHONY: lint test

SHELL_SCRIPTS := $(shell find . -name '*.sh' \
	-not -path './.git/*' \
	-not -path './claude/plugins/*' \
	-not -path './claude/shell-snapshots/*')

lint:
	shellcheck -o all $(SHELL_SCRIPTS)

test:
	cd test && docker build . -t test && docker run --rm test
