"""
Modify the `project` and `version` metadata of an inventory or inventory file.

```julia
new_inventory = set_metadata(
    inventory;
    version=inventory.version,
    project=inventory.project
)
```

returns a new [`Inventory`](@ref) with a modified `version` and/or `project`
attribute.

```julia
set_metadata(
    filename;
    mime=auto_mime(filename),
    project=Inventory(filename).project,
    version=Inventory(filename).version,
)
```

modifies the `project` and/or `version` in the given inventory file
(`objects.inv`, `inventory.toml`, etc.)
"""
function set_metadata(
    inventory::Inventory;
    version=inventory.version,
    project=inventory.project
)
    return Inventory(
        string(project),
        string(version),
        inventory._items,
        inventory.root_url,
        inventory.source,
        inventory.sorted,
    )
end


function set_metadata(filename::AbstractString; mime=auto_mime(filename), kwargs...)
    set_metadata(filename, mime; kwargs...)
end


function set_metadata(filename::AbstractString, mime; kwargs...)
    inventory = set_metadata(Inventory(filename; mime=mime, root_url=""); kwargs...)
    save(filename, inventory; mime)
end


function set_metadata(
    objects_inv::AbstractString,
    mime::Union{MIME"application/x-intersphinx",MIME"text/x-intersphinx"};
    kwargs...
)
    # This is more efficient than the fallback, but more importantly, it is
    # "stable" (doesn't change the original order of item lines in the
    # `objects.inv` file.
    allowed_kwargs = (:project, :version)
    if !issubset(keys(kwargs), Set(allowed_kwargs))
        msg = "Invalid keyword arguments $kwargs. Accepted keyword arguments are $allowed_kwargs."
        throw(ArgumentError(msg))
    end
    objects_inv_patched = tempname()
    open(objects_inv) do input
        open(objects_inv_patched, "w") do output
            for line in eachline(input; keep=true)
                if startswith(line, "# Version: ") && haskey(kwargs, :version)
                    line = "# Version: $(kwargs[:version])\n"
                end
                if startswith(line, "# Project: ") && haskey(kwargs, :project)
                    line = "# Project: $(kwargs[:project])\n"
                end
                write(output, line)
            end
        end
    end
    mv(objects_inv_patched, objects_inv; force=true)
end
