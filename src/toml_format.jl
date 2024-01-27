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

    TOML.println(io, "# DocInventory version 0")
    TOML.print(io, toml_dict; sorted=true)

end


function read_inventory(io::IO, ::MIME"application/toml")
    format_header = readline(io)
    if !startswith(format_header, "#")
        @warn "Invalid format_header: $format_header"
        # TODO: verify format_header more strictly once the format has settled.
    end
    data = TOML.parse(io)
    try
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
                # For backward-compatibility, remove this `elseif` in v1.0
                @warn "Unexpected key: $domain"
            else
                throw(InventoryFormatError("Unexpected key: $domain"))
            end
        end
        return project, version, items
    catch exception
        msg = "Invalid TOML inventory"
        @error msg exception
        throw(InventoryFormatError("Invalid TOML inventory format."))
    end
end
