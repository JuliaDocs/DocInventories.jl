using TOML: TOML


function Base.show(io::IO, ::MIME"application/toml", inventory::Inventory)

    domains = Dict{String,Any}()
    for item in inventory._items
        if !(item.domain in keys(domains))
            domains[item.domain] = Dict{String,Any}()
        end
        if !(item.role in keys(domains[item.domain]))
            domains[item.domain][item.role] = []
        end
        item_data = Dict{String,Any}("name" => item.name, "uri" => item.uri,)
        if item.dispname != "-"
            item_data["dispname"] = item.dispname
        end
        if item.domain == "std"
            if item.priority != -1
                item_data["priority"] = item.priority
            end
        elseif (item.priority != 1)
            item_data["priority"] = item.priority
        end
        push!(domains[item.domain][item.role], item_data)
    end

    toml_dict = Dict("project" => inventory.project, domains...)
    if !isempty(inventory.version)
        toml_dict["version"] = inventory.version
    end

    println(io, "# DocInventory version 1")
    TOML.print(io, toml_dict; sorted=true)

end


function read_inventory(io::IO, ::MIME"application/toml")
    rx_format_header = r"^# DocInventory version (?<version>\d+)$"
    line = readline(io)
    format_header = match(rx_format_header, line)
    if isnothing(format_header)
        @warn "Invalid format_header: $line"
        version = 1  # try as "version 1"
    else
        version = parse(Int, format_header[:version])
        if version > 1
            @warn "Invalid version $version in format header: $line"
        end
        version = 1  # try as "version 1", no matter what
    end
    try
        if version == 1
            return _read_toml_inventory_v1(io)
        else
            error("Invalid inventory version $version")
        end
    catch exception
        msg = "Invalid TOML inventory"
        @error msg exception
        throw(InventoryFormatError("Invalid TOML inventory."))
    end
end


function _read_toml_inventory_v1(io)
    data = TOML.parse(io)
    project = string(pop!(data, "project"))   # mandatory
    version = string(pop!(data, "version", ""))  # optional
    items = InventoryItem[]
    for (domain, domain_data) in data
        if domain_data isa Dict
            for (role, role_data) in domain_data
                for item_data in role_data
                    push!(
                        items,
                        InventoryItem(
                            item_data["name"],
                            domain,
                            role,
                            get(item_data, "priority", (domain == "std") ? -1 : 1),
                            item_data["uri"],
                            get(item_data, "dispname", "-")
                        )
                    )
                end
            end
        elseif domain == "format"
            # For backward-compatibility; remove this `elseif` in v1.0
            @warn "Unexpected key: $domain"
        else
            throw(InventoryFormatError("Unexpected key: $domain"))
        end
    end
    return project, version, items
end
