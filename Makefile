.PHONY: help devrepl test coverage htmlcoverage docs clean codestyle distclean
.DEFAULT_GOAL := help

JULIA ?= julia

define PRINT_HELP_JLSCRIPT
rx = r"^([a-z0-9A-Z_-]+):.*?##[ ]+(.*)$$"
for line in eachline()
    m = match(rx, line)
    if !isnothing(m)
        target, help = m.captures
        println("$$(rpad(target, 20)) $$help")
    end
end
endef
export PRINT_HELP_JLSCRIPT

define DEVREPL_INIT_JLSCRIPT
using Revise
# Disable link-checking in interactive REPL, since it is the slowest part
# of building the docs.
ENV["DOCUMENTER_CHECK_LINKS"] = "0"
println("""
**Development REPL for DocInventories** (Revise active)
""")
endef
export DEVREPL_INIT_JLSCRIPT


help:  ## show this help
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	@julia -e "$$PRINT_HELP_JLSCRIPT" < $(MAKEFILE_LIST)

devrepl:  test/Manifest.toml ## Start an interactive REPL for testing and building documentation
	$(JULIA) --project=test -e "$$DEVREPL_INIT_JLSCRIPT" -i

test: ## Run the test suite
	$(JULIA) --project=. -e 'import Pkg; Pkg.test(;coverage=false, julia_args=["--check-bounds=yes", "--compiled-modules=yes", "--depwarn=yes"], force_latest_compatible_version=false, allow_reresolve=true)'

coverage: test/Manifest.toml ## Run the test suite with coverage
	$(JULIA) --project=test -e 'using LocalCoverage; report = generate_coverage("DocInventories"; run_test = true); show(report)'

htmlcoverage: test/Manifest.toml ## Run the test suite with coverage and generate an HTML report in ./coverage
	$(JULIA) --project=test -e 'using LocalCoverage; html_coverage("DocInventories"; dir = "coverage")'

docs: docs/Manifest.toml ## Build the documentation
	$(JULIA) --project=docs docs/make.jl

clean: ## Clean up build/doc/testing artifacts
	$(JULIA) -e 'include("test/clean.jl"); clean()'

codestyle: test/Manifest.toml ## Apply the codestyle to the entire project
	$(JULIA) --project=test -e 'using JuliaFormatter; format(["src", "docs", "test"], verbose=true)'
	@echo "Done. Consider using 'make devrepl'"

distclean: clean ## Restore to a clean checkout state
	$(JULIA) -e 'include("test/clean.jl"); clean(distclean=true)'

test/Manifest.toml: test/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=test -e 'using Pkg; Pkg.instantiate()'

docs/Manifest.toml: docs/Project.toml
	@git config --local blame.ignoreRevsFile .git-blame-ignore-revs
	$(JULIA) --project=docs -e 'using Pkg; Pkg.instantiate()'
