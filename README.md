# DocInventories.jl

[![Version](https://juliahub.com/docs/DocInventories/version.svg)](https://juliahub.com/ui/Packages/General/DocInventories)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliadocs.org/DocInventories.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliadocs.org/DocInventories.jl/dev)
[![Build Status](https://github.com/JuliaDocs/DocInventories.jl/workflows/CI/badge.svg)](https://github.com/JuliaDocs/DocInventories.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaDocs/DocInventories.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaDocs/DocInventories.jl)

[DocInventories.jl](https://github.com/JuliaDocs/DocInventories.jl#readme) is a package for reading and writing inventory files such as the `objects.inv` file written by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) ≥ `v1.3.0` and [Sphinx](https://www.sphinx-doc.org/en/master/).

These inventory files are used by [DocumenterInterLinks.jl](https://github.com/JuliaDocs/DocumenterInterLinks.jl#readme) and [Intersphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html) to enable linking between the documentation of two projects.

The `DocInventories` package also allows to convert the `objects.inv` format to an `inventory.toml` format that is designed to be human-readable and to allow maintaining custom inventories by hand.


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


## Related Projects

* [Documenter.jl](https://documenter.juliadocs.org/stable/) — The default documentation generator in the [Julia](https://julialang.org) ecosystem. As of version `1.3.0`, `Documenter` automatically generates and deploys a (Sphinx-format) `objects.inv` file that enables linking into a project's documentation.
* [DocumenterInterLinks.jl](http://juliadocs.org/DocumenterInterLinks.jl/stable/) – A plugin for `Documenter` to enable linking to any other project that has an inventory file, i.e., any project using a recent version of `Documenter` to build its documentation, or any project using [Sphinx](https://www.sphinx-doc.org/en/master/). It is the Julia-equivalent of Sphinx' [Intersphinx plugin](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).
* [Sphinx](https://www.sphinx-doc.org/en/master/) – The default documentation generator in the [Python](https://www.python.org) ecosystem. Sphinx originated the `objects.inv` inventory file format now also generated for Julia projects by `Documenter`.
* [sphobjinv](https://sphobjinv.readthedocs.io/en/stable/) – The Python-equivalent of this project, allowing to read, explore and manipulate the data in `objects.inv` inventory file. Note that this does not include support for the `inventory.toml` format, which is unique to `DocInventories`.
