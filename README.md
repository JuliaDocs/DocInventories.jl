# DocInventories.jl

[![Version](https://juliahub.com/docs/DocInventories/version.svg)](https://juliahub.com/ui/Packages/General/DocInventories)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadocs.org/DocInventories.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliadocs.org/DocInventories.jl/dev)
[![Build Status](https://github.com/JuliaDocs/DocInventories.jl/workflows/CI/badge.svg)](https://github.com/JuliaDocs/DocInventories.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaDocs/DocInventories.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaDocs/DocInventories.jl)

[DocInventories.jl](https://github.com/JuliaDocs/DocInventories.jl#readme) is a package for reading and writing inventory files such as the `objects.inv` file used by [Intersphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html). It serves as a backend for [DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme).

## Installation

As usual, the package can be installed via

```
] add DocInventories
```

in the Julia REPL, or by adding

```
DocInventories = "43dc2714-ed3b-44b5-b226-857eda1aa7de"
```

to the relevant `Project.toml` file.


## Usage

This package is primarily used in the context of [DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme). For direct usage, see the [Usage section in the documentation](https://juliadocs.org/DocInventories.jl/stable/usage/).
