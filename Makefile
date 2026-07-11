.PHONY: check lint test

check: lint test

lint:
	./scripts/lint.sh

test:
	./scripts/test.sh
