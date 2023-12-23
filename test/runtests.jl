using Test
using SafeTestsets
using DocInventories: InventoryItem  # required for tests to pass

# Note: comment outer @testset to stop after first @safetestset failure
@time @testset verbose = true "DocInventories" begin

    println("\n* Inventory Items (test_inventory_item.jl):")
    @time @safetestset "test_inventory_item" begin
        include("test_inventory_item.jl")
    end

    println("\n* Inventories (test_inventory.jl):")
    @time @safetestset "test_inventory" begin
        include("test_inventory.jl")
    end

end

nothing  # avoid noise when doing `include("test/runtests.jl")`
