using CodecZlib


const rx_project = r"""
    ^                  # Start of line
    [#][ ]Project:[ ]  # Preamble
    (?P<project>.*)    # Rest of line is project name
    $                  # End of line
"""x

const rx_version = r"""
    ^                   # Start of line
    [#][ ]Version:[ ]   # Preamble
    (?P<version>.*)     # Rest of line is version
    $                   # End of line
"""x

const rx_data = r"""
    ^                    # Start of line
    (?P<name>.+?)        # --> Name
    \s+                  # Dividing space
    (?P<domain>[^\s:]+)  # --> Domain
    :                    # Dividing colon
    (?P<role>[^\s]+)     # --> Role
    \s+                  # Dividing space
    (?P<priority>-?\d+)  # --> Priority
    \s+?                 # Dividing space
    (?P<uri>\S*)         # --> URI
    \s+                  # Dividing space
    (?P<dispname>.+)     # --> Display name
    $                    # End of line
"""x


function Base.show(io::IO, ::MIME"text/x-intersphinx", inventory)
    println(io, "# Sphinx inventory version 2")
    println(io, "# Project: $(inventory.project)")
    println(io, "# Version: $(inventory.version)")
    if !isempty(inventory)
        println(io, "# The remainder of this file would be compressed using zlib.")
        for item in inventory._items
            line = "$(item.name) $(item.domain):$(item.role) $(item.priority) $(item.uri) $(item.dispname)"
            println(io, line)
        end
    else
        println(io, "# This file is empty")
    end
end


function Base.show(io::IO, ::MIME"application/x-intersphinx", inventory)
    println(io, "# Sphinx inventory version 2")
    println(io, "# Project: $(inventory.project)")
    println(io, "# Version: $(inventory.version)")
    if !isempty(inventory)
        println(io, "# The remainder of this file is compressed using zlib.")
        stream = ZlibCompressorStream(io)
        for item in inventory._items
            line = "$(item.name) $(item.domain):$(item.role) $(item.priority) $(item.uri) $(item.dispname)\n"
            write(stream, line)
        end
        close(stream)

    else
        println(io, "# This file is empty")
    end
end


function read_inventory(
    io::IO,
    mime::Union{MIME"application/x-intersphinx",MIME"text/x-intersphinx"}
)

    # Keep the four header lines, which are in plain text
    str = ""
    for _ = 1:4
        str *= readline(io; keep=true)
    end

    # Decompress the rest of the file and append decoded text
    if string(mime) == "application/x-intersphinx"
        if !contains(str, "# This file is empty")
            try
                str *= String(read(ZlibDecompressorStream(io)))
            catch exc
                msg = "Invalid compressed data"
                if exc isa ErrorException
                    msg *= ": $(exc.msg)"
                end
                throw(ArgumentError(msg))
            end
        end
    else
        @assert string(mime) == "text/x-intersphinx"
        str *= read(io, String)
    end

    text_buffer = IOBuffer(str)

    header_line = readline(text_buffer)
    if !(header_line == "# Sphinx inventory version 2")
        msg = "Invalid Sphinx header line. Must be \"# Sphinx inventory version 2\""
        @error msg header_line
        msg = "Only v2 objects.inv files currently supported"
        throw(InventoryFormatError(msg))

    end

    project_line = readline(text_buffer)
    m = match(rx_project, project_line)
    if isnothing(m)
        msg = "Invalid project name line: $(repr(project_line))"
        throw(InventoryFormatError(msg))
    else
        project = m["project"]
    end

    version_line = readline(text_buffer)
    m = match(rx_version, version_line)
    if isnothing(m)
        msg = "Invalid project version line: $(repr(version_line))"
        throw(InventoryFormatError(msg))
    else
        version = m["version"]
    end

    items = InventoryItem[]

    compression_line = readline(text_buffer)
    if contains(compression_line, "# This file is empty")
        return project, version, items
    end
    if !contains(compression_line, "zlib")
        msg = "Invalid compression line $(repr(compression_line))"
        throw(InventoryFormatError(msg))
    end

    for line in readlines(text_buffer)
        m = match(rx_data, line)
        try
            if isnothing(m)
                # Lines that don't fit the pattern for an item may be
                # continuations of a multi-line `dispname`
                o = pop!(items)
                dispname = o.dispname * "\n" * line
                item = InventoryItem(o.name, o.domain, o.role, o.priority, o.uri, dispname)
            else
                item = InventoryItem(;
                    name=m["name"],
                    domain=m["domain"],
                    role=m["role"],
                    priority=parse(Int64, m["priority"]),
                    uri=m["uri"],
                    dispname=m["dispname"],
                )
            end
            push!(items, item)
        catch exc # probably `pop!` from empty `items`
            if !(exc isa ArgumentError)
                @error "Internal Error" exception = (exc, Base.catch_backtrace())
            end
            msg = "Unexpected line: $(repr(line))"
            rethrow(InventoryFormatError(msg))
        end
    end

    return project, version, items

end
