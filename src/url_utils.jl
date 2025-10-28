using Downloads: Downloads

# return array of bytes from url
function _read_url(url; timeout=1.0, retries=3, wait_time=1.0)
    attempt = 0
    while true
        try
            return take!(Downloads.download(url, IOBuffer(); timeout))
        catch exc
            # COV_EXCL_START
            attempt += 1
            if attempt >= retries
                rethrow()
            else
                sleep(wait_time * attempt)
            end
            # COV_EXCL_STOP
        end
    end
end


"""Split a URL into a root URL and a filename.

```julia
root_url, filename = split_url(url)
```

splits `url` at the last slash. This behaves like
[`splitdir`](@extref Julia Base.Filesystem.splitdir), but operates on URLs
instead of file paths. The URL must start with `"https://"` or `"http://"`.
"""
function split_url(url)
    url_match = match(r"^https?://", url)
    if isnothing(url_match)
        msg = "Url $(repr(url)) must start with 'http://' or 'https://'"
        throw(ArgumentError(msg))
    end
    offset = length(url_match.match)
    last_slash_index = findlast('/', url[(1+offset):end])
    if isnothing(last_slash_index)
        return (url, "")
    else
        l = offset + last_slash_index
        return url[1:l], url[(l+1):end]
    end
end


"""Obtain the root url from an inventory source.

```julia
url = root_url(source; warn=true)
```

returns the root url as determined by [`split_url`](@ref) if `source` starts
with `"https://"` or `"http://"`, or an empty string otherwise (if `source` is
a local file path). An empty root url will emit a warning unless `warn=false`.
"""
function root_url(source::AbstractString; warn=true)
    if startswith(source, r"^https?://")
        return split_url(source)[1]
    else
        if warn
            @warn "Empty root url with source=$(repr(source))."
        end
        return ""
    end
end
