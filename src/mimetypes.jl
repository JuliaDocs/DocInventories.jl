# Note: do not remove the link to "Inventory File Formats" in the
# docstring! It is used as an example in the documentatin of
# DocumenterInterLinks
"""Default map of file extensions to MIME types.

```julia
MIME_TYPES = Dict(
    ".txt" => MIME("text/x-intersphinx"),
    ".inv" => MIME("application/x-intersphinx"),
    ".toml" => MIME("application/toml"),
    ".txt.gz" => MIME("text/x-intersphinx+gzip"),
    ".toml.gz" => MIME("application/toml+gzip"),
)
```

See [Inventory File Formats](@ref) for details.
"""
const MIME_TYPES = Dict(
    ".txt" => MIME("text/x-intersphinx"),  # see sphinx_format.jl
    ".inv" => MIME("application/x-intersphinx"),  # see sphinx_format.jl
    ".toml" => MIME("application/toml"),  # see toml_format.jl
    ".txt.gz" => MIME("text/x-intersphinx+gzip"),
    ".toml.gz" => MIME("application/toml+gzip"),
)


# Split off all extensions (e.g., `".toml.gz"`), not just the last one
# (`".gz"`)
function splitfullext(filepath::String)
    root, ext = splitext(filepath)
    full_ext = ext

    # Keep splitting until no more extensions are found
    while ext != ""
        root, ext = splitext(root)
        (ext == "") && break
        full_ext = ext * full_ext
    end
    return root, full_ext
end


"""
Determine the MIME type of the given file path or URL from the file extension.

```julia
mime = auto_mime(source)
```

returns a [`MIME` type](@extref Julia Base.Multimedia.MIME) from the extension
of `source`. The default mapping is in [`MIME_TYPES`](@ref).

Unknown or unsupported extensions throw an `ArgumentError`.
"""
function auto_mime(source)
    try
        ext = splitfullext(source)[2]
        return MIME_TYPES[ext]
    catch exception
        msg = ("Cannot determine MIME type for $(repr(source)): $exception")
        @error msg MIME_TYPES
        rethrow(ArgumentError(msg))
    end
end


function _unknown_mime_msg(mime)
    repr_mime = repr(string(mime))
    """
    Reading and writing an inventory file with a custom MIME type
    requires the following:

    * `DocInventories.MIME_TYPES` should contain a mapping from the
      appropriate file extension to the MIME type.
    * A method `DocInventories.read_inventory(io::IO, mime)` must be
      implemented for mime::MIME$repr_mime and return a string
      `project`, a string `version`, and a list `items` of `InventoryItem`
      instances.
    * A method `Base.show(io::IO, mime, inventory)` must be be implemented for
      mime::MIME$repr_mime.

    Any mime type ending with "+gzip" will automatically delegate to the
    methods for the mime type without the "+gzip" prefix, so the above methods
    can generally assume uncompressed data.
    """
end
