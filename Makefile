# ABOUTME: Hugo blog build targets used by the pre-commit gate
# ABOUTME: `check` and `test-e2e` both run a quiet Hugo build to verify the site compiles

.PHONY: check test-e2e build clean

check:
	hugo --gc --minify --quiet

test-e2e: check

build:
	hugo --gc --minify

clean:
	rm -rf public resources
