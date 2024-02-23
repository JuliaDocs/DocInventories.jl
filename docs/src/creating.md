# Creating Inventory Files

In general, inventory files should be generated automatically by [Documenter](@extref Documenter :doc:`index`) or [Sphinx](@extref sphinx :doc:`index`). However, there are situations where producing and inventory file "by hand" make sense:

* A project does not provide an inventory file. Maybe its documentation is entirely in its Github README file.

* Creating an inventory file for convenient linking to a website other than a project documentation. For example, one could create an inventory of (select) Wikipedia pages.

There are two ways to accomplish this:

1. [Populate an Inventory in the REPL](@ref)
2. [Maintain an Inventory TOML File by Hand](@ref)


## Populate an Inventory in the REPL

We can instantiate an empty [`Inventory`](@ref) as

```@example creating
using DocInventories

inventory = Inventory(
    project="Wikipedia",
    version="2024-01",
    root_url="https://en.wikipedia.org/wiki/"
);
nothing # hide
```

Then, we can [`push!`](@extref Julia Base.push!) [`InventoryItems`](@ref InventoryItem) for all pages we want to include in the inventory:


```@example creating
push!(
    inventory,
    InventoryItem(
        ":std:doc:Julia" => "Julia_(programming_language)";
        dispname="Julia (programming language)"
    ),
    InventoryItem(
        ":std:doc:Python" => "Python_(programming_language)";
        dispname="Python (programming language)"
    )
)
```

We've used here the role `:std:doc:` for "documents", which is somewhat optional, but semantically more accurate than the default `":std:label:"` role for a section within a document. In any case, as shown in [Usage](@ref), items can be looked without referring to the domain or role:

```@example creating
inventory["Julia"]
```

Once the inventory is complete, we can write it to disk, see [Saving Inventories to File](@ref).

```@example creating
DocInventories.save("$(tempname()).toml", inventory)
```

## Maintain an Inventory TOML File by Hand


Alternatively, we could just write a TOML inventory file by hand, in our favorite text editor. For the above inventory, the file should contain


```@example creating
show(stdout, "application/toml", inventory)
```

The requirements for the file are in the description of the [TOML Format](@ref), but should be fairly intuitive.

In general, custom inventory files should be stored as an uncompressed `.toml` file. This makes them much easier to maintain with a text editor. In addition, these inventories will presumably be checked into a `git` repository, which will be much more efficient with uncompressed (diffable!) text-based files.

In contrast, inventories that are *deployed* (put online so that other projects may download them to resolve links) should always be compressed, either as an [`objects.inv` file](@ref Sphinx-Inventory-Format) or as an [`inventory.toml.gz` file](@ref TOML-Format).
