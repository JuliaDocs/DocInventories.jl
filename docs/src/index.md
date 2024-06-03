# DocInventories.jl

```@eval
using Markdown
using Pkg

VERSION = Pkg.dependencies()[Base.UUID("43dc2714-ed3b-44b5-b226-857eda1aa7de")].version

github_badge = "[![Github](https://img.shields.io/badge/JuliaDocs-DocInventories.jl-blue.svg?logo=github)](https://github.com/JuliaDocs/DocInventories.jl)"

version_badge = "![v$VERSION](https://img.shields.io/badge/version-v$(replace("$VERSION", "-" => "--"))-green.svg)"

if get(ENV, "DOCUMENTER_BUILD_PDF", "") == ""
    Markdown.parse("$github_badge $version_badge")
else
    Markdown.parse("""
    -----

    On Github: [JuliaDocs/DocInventories.jl](https://github.com/JuliaDocs/DocInventories.jl)

    Version: $VERSION

    -----

    """)
end
```

[DocInventories.jl](@extref JuliaDocs) is a package for reading and writing inventory files such as the `objects.inv` file written by [Documenter.jl](@extref Documenter :doc:`index`) ≥ `v1.3.0` and [Sphinx](@extref sphinx :doc:`index`).


These inventory files are used by [DocumenterInterLinks.jl](@extref JuliaDocs) and [InterSphinx](@extref sphinx usage/extensions/intersphinx) to enable linking between the documentation of two projects.

The `DocInventories` package also allows to convert the [`objects.inv` format](@ref "Sphinx Inventory Format") to an [`inventory.toml` format](@ref "TOML Format") that is designed to be human-readable and to allow maintaining custom inventories by hand. The package is intended for use in the REPL, to interactively explore inventory files, and as a backend for [DocumenterInterLinks](@extref JuliaDocs).


## Installation

As usual, that package can be installed via

```
] add DocInventories
```

in the Julia REPL, or by adding

```
DocInventories = "43dc2714-ed3b-44b5-b226-857eda1aa7de"
```

to the relevant `Project.toml` file.

## Contents

```@contents
Pages = [page for (name, page) in Main.PAGES[2:end]]
```

## Changelog

The `DocInventories` project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). You can find a [`CHANGELOG` for versions after `v1.0`](https://github.com/JuliaDocs/DocInventories.jl/blob/master/CHANGELOG.md) online.


## Related Projects

* [Documenter.jl](https://documenter.juliadocs.org/stable/) — The default documentation generator in the [Julia](https://julialang.org) ecosystem. As of version `1.3.0`, `Documenter` automatically generates and deploys a ([Sphinx-format](@ref "Sphinx Inventory Format")) `objects.inv` file that enables linking into a project's documentation.
* [DocumenterInterLinks.jl](http://juliadocs.org/DocumenterInterLinks.jl/stable/) – A plugin for `Documenter` to enable linking to any other project that has an inventory file, i.e., any project using a recent version of `Documenter` to build its documentation, or any project using [Sphinx](https://www.sphinx-doc.org/en/master/). It is the Julia-equivalent of Sphinx' [Intersphinx plugin](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).
* [Sphinx](https://www.sphinx-doc.org/en/master/) – The default documentation generator in the [Python](https://www.python.org) ecosystem. Sphinx originated the [`objects.inv` inventory file format](@ref "Sphinx Inventory Format") now also generated for Julia projects by `Documenter`.
* [sphobjinv](https://sphobjinv.readthedocs.io/en/stable/) – The Python-equivalent of this project, allowing to read, explore and manipulate the data in `objects.inv` inventory file. Note that this does not include support for the [`inventory.toml` format](@ref "TOML Format"), which is unique to `DocInventories`.
