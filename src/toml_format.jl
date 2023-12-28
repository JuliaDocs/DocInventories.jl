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

    toml_dict = Dict(
        "Inventory" => Dict(
            "format" => "DocInventories v1",
            "project" => inventory.project,
            "version" => inventory.version,
        ),
        domains...
    )

    TOML.print(io, toml_dict; sorted=true)

end


function read_inventory(buffer, ::MIME"application/toml")
    data = TOML.parse(buffer)
    try
        inventory_format = data["Inventory"]["format"]
        if inventory_format != "DocInventories v1"
            msg = "Invalid inventory format: $(repr(inventory_format))"
            throw(InventoryFormatError(msg))
        end
        project = data["Inventory"]["project"]
        version = data["Inventory"]["version"]
        items = InventoryItem[]
        for (domain, domain_data) in data
            (domain == "Inventory") && continue  # that's the header, not a domain
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
        end
        return project, version, items
    catch exception
        msg = "Invalid TOML inventory"
        @error msg exception
        throw(InventoryFormatError("Invalid TOML inventory format."))
    end
end
