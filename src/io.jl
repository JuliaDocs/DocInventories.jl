using CodecZlib


# Backend for `Inventory(source, …)`. The "+gzip" part of any MIME type is
# handled here, but any base MIME type should define a custom method for
# `read_inventory`.
#
# This function is not part of the public API.
function read_inventory(io::IO, mime::Any)
    try
        mime_str = string(mime)
        gzip_suffix = "+gzip"
        if endswith(mime_str, gzip_suffix)
            inner_mime = MIME(chop(mime_str, tail=length(gzip_suffix)))
            io_uncompressed = GzipDecompressorStream(io)
            project, version, items = read_inventory(io_uncompressed, inner_mime)
            close(io_uncompressed)
            return project, version, items
        else
            throw(ArgumentError("Invalid mime format $(mime)."))
        end
    catch exception
        msg = _unknown_mime_msg(mime)
        @error msg MIME_TYPES exception
        rethrow()
    end
end


"""Write the [`Inventory`](@ref) to file in the specified format.

```julia
DocInventories.save(filename, inventory; mime=auto_mime(filename))
```

writes `inventory` to `filename` in the specified MIME type. By default, the
MIME type is derived from the file extension of `filename` via
[`auto_mime`](@ref).
"""
function save(filename::AbstractString, inventory; mime=auto_mime(filename))
    mime = MIME(mime)
    save(filename, inventory, mime)
end


# positional argument
function save(filename::AbstractString, inventory, mime)
    mime = MIME(mime)
    mime_str = string(mime)
    compressed = false
    gzip_suffix = "+gzip"
    if endswith(mime_str, gzip_suffix)
        mime = MIME(chop(mime_str, tail=length(gzip_suffix)))  # inner MIME
        compressed = true
    end
    open(filename, "w") do io
        try
            if compressed
                io_compressed = GzipCompressorStream(io)
                show(io_compressed, mime, inventory)
                close(io_compressed)
            else
                show(io, mime, inventory)
            end
        catch exception
            if exception isa MethodError
                msg = _unknown_mime_msg(mime)
                @error msg MIME_TYPES exception
            end
            rethrow()
        end
    end
end


"""Convert an inventory file.

```julia
DocInventories.convert("objects.inv", "inventory.toml")
```

converts the input file `"objects.inv"` in the [Sphinx Inventory Format](@ref)
to the [TOML Format](@ref) `"inventory.toml"`.

This is a convenience function to simply load an [`Inventory`](@ref) from the
input file and write it to the output file. Both the input and output file must
have known file extensions. The `project` and `version` metadata may be given
as additional keyword arguments to be written to the output file, see
[`set_metadata`](@ref).
"""
function convert(file_in, file_out; kwargs...)
    inventory = Inventory(file_in; root_url="")
    inventory = set_metadata(inventory; kwargs...)
    save(file_out, inventory)
end
