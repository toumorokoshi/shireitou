# Linting and formatting. See specs/linting.md.

prettier := "npx --yes prettier@3.3.3"

# Check formatting and linting.
lint:
    {{prettier}} --check "**/*.md"

# Format files.
format:
    {{prettier}} --write "**/*.md"

# Apply formatting and lint fixes.
fix: format
