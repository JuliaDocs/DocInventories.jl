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

    On Github: [JuliaDocs/DocumenterCitations.jl](https://github.com/JuliaDocs/DocumenterCitations.jl)

    Version: $VERSION

    -----

    """)
end
```

[DocInventories.jl](@extref JuliaDocs) is a package for reading and writing inventory files such as the `objects.inv` file used by [InterSphinx](@extref sphinx usage/extensions/intersphinx) and [DocumenterInterLinks.jl](@extref JuliaDocs). It is designed to be used in the REPL, to interactively explore inventory files, and as a backend for [DocumenterInterLinks](@extref JuliaDocs).


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
