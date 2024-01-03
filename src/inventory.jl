"""An inventory link targets in a project documentation.

```julia
inventory = Inventory(
    source;
    mime=auto_mime(source),
    root_url=root_url(source)
)
```

loads an inventory file from the given `source`, which can be a URL or the path
to a local file. If it is a URL, the options `timeout` (seconds to wait for
network connections), `retries` (number of times to retry) and `wait_time`
(seconds longer to wait between each retry) may be given. The `source` must
contain data in the given mime type. By default, the mime type is derived from
the file extension, via [`auto_mime`](@ref).

The `Inventory` acts as a collection of [`InventoryItems`](@ref InventoryItem),
representing all the objects, sections, or other linkable items in the online
documentation of a project.

Alternatively,

```julia
inventory = Inventory(; project, version="", root_url="", items=[])
```

with a mandatory `project` argument instantiates an `inventory` with the
[`IventoryItems`](@ref InventoryItem) in `items`. If `items` is not given, the
resulting empty `inventory` can have [`InventoryItems`](@ref InventoryItem)
added afterwards via [`push!`](@extref Julia Base.push!).


# Attributes

* `project`: The name of the project
* `version`: The version of the project (e.g., `"1.0.0"`)
* `root_url`: The root URL to which the `item.uri` of any
  [`InventoryItem`](@ref) is relative. If not empty, should start with
  `"https://"` and end with a slash.
* `source`: The URL or filename from which the inventory was loaded, or a
   comment if the inventory was constructed otherwise.
* `sorted`: A boolean to indicate whether the items are sorted by their `name`
   attribute, allowing for efficient lookup. This is `true` for all inventories
   loaded from a URL or file and `false` for manually instantiated inventories.

# Item access

Items can be accessed via iteration (`for item in inventory`), by numeric index
(`inventory[1]`, `inventory[2]`, … `inventory[end]`), or by lookup:
`inventory[name]` or `inventory[spec]`, where `spec` is a string of the form
```":[domain:]role:`name`"```, see the discussion of `spec` in
[`InventoryItem`](@ref). The lookup delegates to [`find_in_inventory`](@ref)
with `quiet=true` and takes into account [`item.priority`](@ref InventoryItem).

# Search

The inventory can be searched by calling `inventory(search;
include_hidden_priority=true)`. This returns a list of all items that contain
`search` in `spec(item)` or `repr(item; context=(:full => true))`. Typically,
`search` would be a string or a [`Regex`](@extref Julia man-regex-literals).
Some examples for common searches:

* A `spec` of the form ```":domain:role:`name`"```, in full, partially, or as a
  regex.
* Part of a url of a page in the project's documentation, as a string
* The title of a section as it appears somewhere in the project's
  documentation.

The search results are sorted by [`abs(item.priority)`](@ref InventoryItem). If
`include_hidden_priority=false`, negative `item.priority` values are omitted.

# Methods

* [`find_in_inventory(inventory, name)`](@ref find_in_inventory)
  – find a single item in the `inventory`
* [`save(filename, inventory; mime=auto_mime(filename))`](@ref save)
  – write the `inventory` to a file in any supported output format.
* [`show_full(inventory)`](@ref) – show the unabbreviated inventory in the
  REPL (ideally via
  [`TerminalPager`](https://ronisbr.github.io/TerminalPager.jl/))
* [`uri(inventory, key)`](@ref uri(::Inventory, key)) – obtain the full URI for
  an item from the `inventory`.
* [`push!(inventory, items...)`](@extref Julia Base.push!) – add
  [`InventoryItems`](@ref InventoryItem) to an existing `inventory`.
* [`append!(inventory, collections...)`](@extref Julia Base.append!) – add
  collections of [`InventoryItems`](@ref InventoryItem) to an existing
  `inventory`.
* [`sort(inventory)`](@extref Julia Base.sort) – convert an unsorted inventory
  into a sorted one.
"""
struct Inventory
    project::String
    version::String
    _items::Vector{InventoryItem}  # do not mutate! (screws up sorted search)
    root_url::String
    source::String
    sorted::Bool
end


function Inventory(; project, version="", root_url="", items=InventoryItem[])
    Inventory(project, string(version), items, root_url, "", false)
end

function Inventory(
    source::AbstractString;
    mime=auto_mime(source),
    root_url=root_url(source),
    timeout=1.0,
    retries=3,
    wait_time=1.0
)
    if contains(source, r"^https?://")
        bytes = _read_url(source; timeout=timeout, retries=retries, wait_time=wait_time)
    else
        bytes = read(source)
    end
    buffer = IOBuffer(bytes)
    mime = MIME(mime)
    try
        project, version, items = read_inventory(buffer, mime)
        items = sort(items; by=(item -> item.name))
        sorted = true
        return Inventory(project, version, items, root_url, source, sorted)
    catch exception
        @error "Could not load Inventory from $source" exception
        if exception isa InventoryFormatError
            rethrow()
        else
            rethrow(ArgumentError("Invalid source/mime for loading Inventory."))
        end
    end
end


function Base.propertynames(inventory::Inventory, private::Bool=false)
    # Note that `private` is not a keyword arg!
    if private
        return fieldnames(Inventory)
    else
        return Tuple(name for name in fieldnames(Inventory) if name != :_items)
    end
end

Base.length(inventory::Inventory) = length(inventory._items)
Base.iterate(inventory::Inventory) = iterate(inventory._items)
Base.iterate(inventory::Inventory, state) = iterate(inventory._items, state)
Base.getindex(inventory::Inventory, ind::Int64) = getindex(inventory._items, ind)
Base.firstindex(inventory::Inventory) = firstindex(inventory._items)
Base.lastindex(inventory::Inventory) = lastindex(inventory._items)
Base.eltype(::Inventory) = InventoryItem


# How an `inventory ` object gets interpolated into a string
function Base.show(io::IO, inventory::Inventory)
    source = inventory.source
    if isempty(source)
        print(io, "Inventory(")
        print(io, repr(inventory.project), ", ")
        print(io, repr(inventory.version), ", ")
        print(io, repr(inventory._items), ", ")
        print(io, repr(inventory.root_url), ", ")
        print(io, repr(inventory.source), ", ")
        print(io, repr(inventory.sorted), ")")
    else
        write(io, "Inventory($(repr(source))")
        if inventory.root_url != root_url(inventory.source; warn=false)
            write(io, "; root_url=$(repr(inventory.root_url))")
        end
        write(io, ")")
    end
    nothing
end


# How an `inventory` object shows in the REPL
function Base.show(io::IO, ::MIME"text/plain", inventory::Inventory)
    println(io, "Inventory(")
    println(io, " project=$(repr(inventory.project)),")
    println(io, " version=$(repr(inventory.version)),")
    println(io, " root_url=$(repr(inventory.root_url)),")
    N = length(inventory._items)
    if N == 0
        println(io, " items=[]")
    else
        println(io, " items=[")
        limit = get(io, :limit, false)
        N = length(inventory._items)
        if (N < 15) || !limit
            for item in inventory
                write(io, "  ")
                show(io, item)
                write(io, ",\n")
            end
        else
            for i = 1:5
                write(io, "  ")
                show(io, inventory[i])
                write(io, ",\n")
            end
            println(io, "  ⋮ ($N elements in total)")
            for i = N-5:N
                write(io, "  ")
                show(io, inventory[i])
                write(io, ",\n")
            end
        end
        println(io, " ]")
    end
    println(io, ")")
    nothing
end


"""
```julia
show_full(inventory)  # io=stdout
show_full(io, inventory)
```

is equivalent to

```julia
show(IOContext(io, :limit => false), "text/plain", inventory)
```

and shows the entire [`inventory`](@ref Inventory) without truncating the list
of items. This may produce large output, so you may want to make use of the
[`TerminalPager`](https://ronisbr.github.io/TerminalPager.jl/) package.
"""
function show_full(inventory::Inventory)
    show_full(stdout, inventory)
end

function show_full(io::IO, inventory::Inventory)
    show(IOContext(io, :limit => false), "text/plain", inventory)
end


"""Find an item in the inventory.

```julia
item = find_in_inventory(
    inventory,
    name;
    domain="",
    role="",
    quiet=false,
    include_hidden_priority=true
)
```

returns the top priority [`InventoryItem`](@ref) matching the given `name`. If
the `inventory` contains no matching item, returns `nothing`.

# Arguments

* `inventory`: The [`Inventory`](@ref) to search.
* `name`: The value of the `name` attribute of the [`InventoryItem`](@ref) to
  find. Must match exactly.
* `domain`: If not empty, restrict search to items with a matching `domain`
  attribute.
* `role`: If not empty, restrict search to items with a matching `role`
  attribute.
* `quiet`: If `false` (default), log a warning if the item specification is
  ambiguous (the top priority item of multiple candidates is returned). If no
  matching item can be found, an error will be logged in addition to returning
  `nothing`.
* `include_hidden_priority`: Whether or not to consider items with a negative
  `priority` attribute. If "hidden" items are included (default), they are
  sorted by the absolute value of the `priority`. That is, items with
  `priority=-1` and `priority=1` are considered to be equivalent.

Note that direct item lookup as [`inventory[spec]`](@ref Inventory) where
`spec` is a string of the form ```"[:[domain:]role:]`name`"``` is available as
a simplified way to call `find_in_inventory` with `quiet=true`.
"""
function find_in_inventory(
    inventory,
    name;
    domain::String="",
    role::String="",
    quiet=false,
    include_hidden_priority=true,
)::Union{Nothing,InventoryItem}
    items = inventory._items
    if inventory.sorted
        # https://discourse.julialang.org/t/searchsorted-by-attribute/107754/4
        x = InventoryItem(name=name, domain="any", role="any", uri="any")
        found = searchsorted(items, x; by=(item -> item.name))
        candidates = items[found]
    else
        idxs = findall(item -> (item.name == name), items)
        candidates = items[idxs]
    end
    if !isempty(domain)
        candidates = filter(item -> (item.domain == domain), candidates)
    end
    if !isempty(role)
        candidates = filter(item -> (item.role == role), candidates)
    end
    if !include_hidden_priority
        candidates = filter(item -> (item.priority >= 0), candidates)
    end
    if length(candidates) > 1
        sort!(candidates; by=(item -> abs(item.priority)))
        quiet ||
            @warn "Ambiguous search in inventory=$inventory" name domain role candidates
    end
    if length(candidates) > 0
        return candidates[1]
    else
        quiet || @error "Cannot find item in inventory=$inventory" name domain role
        return nothing
    end
end


function Base.getindex(inventory::Inventory, key)
    try
        domain, role, name = _split_domain_role_name(key)
        return find_in_inventory(inventory, name; domain=domain, role=role, quiet=true)
    catch exc
        @error "Invalid key for inventory" key
        return nothing
    end
end


# exposed as `inventory(search; include_hidden_priority)`
function search_in_inventory(inventory, search; include_hidden_priority=true,)
    results = InventoryItem[]
    for item in inventory
        if !include_hidden_priority && (item.priority < 0)
            continue
        end
        if contains(spec(item), search)
            push!(results, item)
        elseif contains(repr(item; context=(:full => true)), search)
            push!(results, item)
        end
    end
    return sort(results; by=(item -> abs(item.priority)))
end


function (inventory::Inventory)(search; include_hidden_priority=true)
    return search_in_inventory(
        inventory,
        search;
        include_hidden_priority=include_hidden_priority
    )
end


function Base.push!(inventory::Inventory, items...)
    if inventory.sorted
        for item in items
            insert_idx = searchsortedfirst(inventory._items, item, by=(item -> item.name))
            insert!(inventory._items, insert_idx, item)
        end
    else
        append!(inventory._items, items)
    end
end

function Base.append!(inventory::Inventory, collections...)
    if inventory.sorted
        for collection in collections
            push!(inventory, collection...)
        end
    else
        append!(inventory._items, collections...)
    end
end

function Base.sort(inventory::Inventory)
    if inventory.sorted
        return inventory
    else
        sorted = true
        return Inventory(
            inventory.project,
            inventory.version,
            sort(inventory._items; by=(item -> item.name)),
            inventory.root_url,
            inventory.source,
            sorted
        )
    end
end


"""
```julia
uri_str = uri(inventory, key)
```

is equivalent to `uri(inventory[key]; root_url=inventory.root_url)`.
"""
function uri(inventory::Inventory, key)
    return uri(inventory[key]; root_url=inventory.root_url)
end


"""An error indicating an issue with an `objects.inv` file.

```julia
throw(InventoryFormatError(msg))
```
"""
struct InventoryFormatError <: Exception
    msg::String
end
