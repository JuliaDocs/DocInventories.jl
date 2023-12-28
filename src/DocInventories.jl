module DocInventories

export Inventory, InventoryItem


include("inventory_item.jl")
include("inventory.jl")
include("toml_format.jl")


end
