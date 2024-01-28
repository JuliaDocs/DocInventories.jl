@doc raw"""
An item inside an [`Inventory`](@ref).

```julia
item = InventoryItem(; name, role, uri, priority=1, domain="jl", dispname="-")
```

represents a linkable item inside a project documentation, referenced by
`name`. The `domain` and `role` take their semantics from the
[Sphinx project](@extref sphinx usage/domains/index), see *Attributes* for
details on these parameters, as well as `priority` and `dispname`. The `uri` is
relative to a project root, which should be the
[`Inventory.root_url`](@ref Inventory) of the `inventory` containing the
`InventoryItem`.

For convenience, an `InventoryItem` can also be instantiated from a mapping
`spec => uri`, where ```spec=":domain:role:`name`"``` borrows from Sphinx'
[cross-referencing syntax](@extref sphinx usage/referencing):

```julia
item = IventoryItem(
    ":domain:role:`name`" => uri;
    dispname=<name>,
    priority=(<domain == "std" ? -1 : 1>)
)
```

The `domain` is optional: if ```spec=":role:`name`"```, the `domain` is `"std"`
for `role="label"` or `role="doc"`, and `"jl"` otherwise. The `role` is
mandatory for code objects. For non-code objects,

```julia
item = IventoryItem(
    "title" => uri;
    dispname=<title>,
    priority=-1
)
```

indicates a link to a section header in the documentation of a project. The
`name` will be a sluggified version of the title, making the `item` equivalent
to ```item = IventoryItem(":std:label:`name`" => uri; dispname=title,
priority=-1)```.

# Attributes

* `name`: The object name for referencing. For code objects, this should be the
   fully qualified name. For section names, it may be a slugified
   version of the section title. It must have non-zero length.

* `domain`: The name of a [Sphinx domain](@extref sphinx usage/domains/index).
   Should be `"jl"` for Julia code objects (default), `"py"` for Python code
   objects, and `"std"` for text objects such as section names. Must have
   non-zero length, and must not contain whitespace or a colon.

* `role`: A domain-specific [role](@extref sphinx :term:`role`)
  ([type](@extref sphinx sphinx.domains.ObjType)). Must have nonzero length and
  not contain whitespace.

* `priority`: An integer flag for placement in search results. Used when
  searching in an [`Inventory`](@ref), for item access in an
  [`Inventory`](@ref), and with [`find_in_inventory`](@ref). The following flag
  values are supported:

  - `1`: the "default" priority. Used by default for all objects not in the
    `"std"` domain (that is, all "code" objects such as those in the `"jl"`
    domain).
  - `0`: object is important
  - `2` (or higher): object is unimportant
  - `-1` (or lower): object is "hidden" (may be omitted from search). Used by
    default for all objects in the `std` domain (section titles)

  See [`find_in_inventory`](@ref) for details. The above semantics match those
  used by [Sphinx](https://github.com/sphinx-doc/sphinx/blob/2f60b44999d7e610d932529784f082fc1c6af989/sphinx/domains/__init__.py#L370-L381).

* `uri`: A URI for the location of the object's documentation,
  relative to the location of the inventory file containing the `item`. Must
  not contain whitespace. May end with `"$"` to indicate a placeholder for
  `name` (usually as `"#$"`, for an HTML anchor matching `name`).

* `dispname`: A full plain text representation of the object. May be `"-"` if
  the display name is identical to `name` (which it should be for code
  objects). For section titles, this should be the plain text of the title,
  without formatting, but not slugified.

# Methods

* [`uri`](@ref) – Extract the full URI, resolving the `$` placeholder and
  prepending a `root_url`, if applicable.
* [`dispname`](@ref) – Extract the `dispname`, resolving the "-" shorthand, if
  applicable.
* [`spec`](@ref) – Return the specification string ```":domain:role:`name`"```
  associated with the item
"""
struct InventoryItem

    name::String
    domain::String
    role::String
    priority::Int
    uri::String
    dispname::String

    function InventoryItem(
        name::AbstractString,
        domain::AbstractString,
        role::AbstractString,
        priority::Integer,
        uri::AbstractString,
        dispname::AbstractString
    )
        isempty(name) && throw(ArgumentError("`name` must have non-zero length."))
        startswith(name, "#") && throw(ArgumentError("`name` must not start with `#`."))
        isempty(domain) && throw(ArgumentError("`domain` must have non-zero length."))
        contains(domain, r"[\s:]") &&
            throw(ArgumentError("`domain` must not contain whitespace or colon."))
        isempty(role) && throw(ArgumentError("`role` must have non-zero length."))
        contains(role, r"\s") && throw(ArgumentError("`role` must not contain whitespace."))
        contains(uri, r"\s") && throw(ArgumentError("`uri` must not contain whitespace."))
        startswith(uri, r"https?://") && throw(ArgumentError("`uri` must be relative."))
        while (startswith(uri, "/"))
            uri = chop(uri, head=1, tail=0)
        end
        if endswith(uri, name)
            uri = uri[begin:end-length(name)] * "\$"
        end
        isempty(dispname) && throw(ArgumentError("`dispname` must have non-zero length."))
        if dispname == name
            dispname = "-"
        end
        new(strip(name), domain, role, priority, uri, strip(dispname))
    end

end


function InventoryItem(; name, role, uri, domain="jl", priority=1, dispname="-")
    InventoryItem(name, domain, role, priority, uri, dispname)
end


const _rx_domain_role_name = r"^(:((?<domain>\w+):)?((?<role>\w+):)?)?(?<name>.+)$"


function _split_domain_role_name(domain_role_name::AbstractString)
    m = match(_rx_domain_role_name, domain_role_name)
    if isnothing(m)
        throw(ArgumentError("Invalid inventory key: $(repr(domain_role_name))"))
    end
    name = m["name"]
    if startswith(name, "`") && endswith(name, "`")
        name = chop(name, head=1, tail=1)
    end
    if isnothing(m["role"])
        # If only a role is given (":function:f"), the `func` syntactically
        # looks like a domain, according to the regex
        role = isnothing(m["domain"]) ? "" : string(m["domain"])
        domain = ""
    else
        role = string(m["role"])
        domain = string(m["domain"])
    end
    return domain, role, name
end


# Should match Documenter.slugify
function slugify(s::AbstractString)
    s = replace(s, r"\s+" => "-")
    s = replace(s, r"&" => "-and-")
    s = replace(s, r"[^\p{L}\p{P}\d\-]+" => "")
    s = strip(replace(s, r"\-\-+" => "-"), '-')
    return s
end


function InventoryItem(pair::Pair; dispname=nothing, priority=nothing)
    spec, uri = pair
    domain, role, name = _split_domain_role_name(spec)
    dispname = isnothing(dispname) ? name : dispname
    if isempty(domain)
        if isempty(role)
            if endswith(spec, "`")
                throw(ArgumentError("No role in $(repr(spec))"))
            else
                domain = "std"
                role = "label"
                name = slugify(name)
            end
        else
            if (role == "label") || (role == "doc")
                domain = "std"
            else
                domain = "jl"
            end
        end
    end
    if isnothing(priority)
        priority = (domain == "std") ? -1 : 1
    end
    return InventoryItem(name, domain, role, priority, uri, dispname)
end


# How an `InventoryItems ` gets interpolated into a string or shows as part of
# an Inventory
function Base.show(io::IO, item::InventoryItem)
    full = get(io, :full, false)
    domain = item.domain
    priority = item.priority
    write(io, "InventoryItem(")
    if full
        write(io, "name=$(repr(item.name)), ")
        write(io, "domain=$(repr(domain)), ")
        write(io, "role=$(repr(item.role)), ")
        write(io, "priority=$(repr(priority)), ")
        write(io, "uri=$(repr(uri(item))), ")
        write(io, "dispname=$(repr(dispname(item)))")
    else
        has_default_priority = (priority == 1)
        if domain == "std"
            has_default_priority = (priority == -1)
        end
        has_default_dispname = (item.dispname == "-")
        spec = ":$(domain):$(item.role):`$(item.name)`"
        write(io, repr(spec), " => ", repr(item.uri))
        if !has_default_priority
            write(io, ", priority=$(repr(priority))")
        end
        if !has_default_dispname
            write(io, ", dispname=$(repr(item.dispname))")
        end
    end
    write(io, ")")
    return nothing
end


# How an `InventoryItems` shows in the REPL
function Base.show(io::IO, ::MIME"text/plain", item::InventoryItem)
    full = get(io, :full, false)
    domain = item.domain
    priority = item.priority
    if full
        write(io, "InventoryItem(\n")
        write(io, "  name=$(repr(item.name)),\n")
        write(io, "  domain=$(repr(domain)),\n")
        write(io, "  role=$(repr(item.role)),\n")
        write(io, "  priority=$(repr(priority)),\n")
        write(io, "  uri=$(repr(uri(item))),\n")
        write(io, "  dispname=$(repr(dispname(item)))\n")
        write(io, ")")
    else
        has_default_priority = (priority == 1)
        if domain == "std"
            has_default_priority = (priority == -1)
        end
        has_default_dispname = (item.dispname == "-")
        spec = ":$(domain):$(item.role):`$(item.name)`"
        write(io, "InventoryItem(")
        if has_default_priority && has_default_dispname
            # single-line repr
            write(io, repr(spec), " => ", repr(item.uri))
        else
            # multi-line repr
            write(io, "\n  ", repr(spec), " => ", repr(item.uri))
            if !has_default_priority
                write(io, ",\n  priority=$(repr(priority))")
            end
            if !has_default_dispname
                write(io, ",\n  dispname=$(repr(item.dispname))")
            end
            write(io, "\n")
        end
        write(io, ")")
    end
    return nothing
end


"""
```julia
show_full(item)  # io=stdout
show_full(io, item)
```

is equivalent to

```julia
show(IOContext(io, :full => true), "text/plain", item)
```

and shows the [`InventoryItem`](@ref) with all attributes.
"""
function show_full(item::InventoryItem)
    show_full(stdout, item)
end


function show_full(io::IO, item::InventoryItem)
    show(IOContext(io, :full => true), "text/plain", item)
end


"""
```julia
uri_str = uri(item; root_url="")
```

fully expands `item.uri` and prepends `root_url`.
"""
function uri(item::InventoryItem; root_url::AbstractString="")
    _uri = item.uri
    if endswith(_uri, "\$")
        _uri = chop(_uri) * item.name
    end
    return root_url * _uri
end


""" Return the specification string of an [`InventoryItem`](@ref).

```julia
item_spec = spec(item)
```

returns a string of the form ```":domain:role:`name`"``` using the attributes
of the given `item`.
"""
spec(item::InventoryItem) = ":$(item.domain):$(item.role):`$(item.name)`"


"""Obtain the full display name for an [`InventoryItem`](@ref).

```julia
display_name = dispname(item)
```

returns `item.dispname` with `"-"` expanded to `item.name`.
"""
function dispname(item::InventoryItem)
    return item.dispname == "-" ? item.name : item.dispname
end
