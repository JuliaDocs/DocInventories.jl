using Test
using TestingUtilities: @Test
using DocInventories: InventoryItem, uri, dispname, spec, get_inventory_role
using Documenter: Documenter, makedocs


@testset "InventoryItem" begin

    item = InventoryItem(name="Documenter.makedocs", role="func", uri="lib/public/#\$")
    @test item.domain == "jl"
    @test item.dispname == "-"
    @Test repr(item) ==
          "InventoryItem(\":jl:func:`Documenter.makedocs`\" => \"lib/public/#\\\$\")"

    item = InventoryItem(makedocs => "lib/public/Documenter.makedocs")
    @test item.name == "Documenter.makedocs"
    @test item.domain == "jl"
    @test item.role == "func"
    @test item.uri == "lib/public/\$"
    @test uri(item) == "lib/public/Documenter.makedocs"
    @test item.dispname == "-"
    @test dispname(item) == "Documenter.makedocs"
    @Test repr(item) ==
          "InventoryItem(\":jl:func:`Documenter.makedocs`\" => \"lib/public/\\\$\")"
    @Test repr(item; context=(:full => true)) ==
          "InventoryItem(name=\"Documenter.makedocs\", domain=\"jl\", role=\"func\", priority=1, uri=\"lib/public/Documenter.makedocs\", dispname=\"Documenter.makedocs\")"
    @test spec(item) == ":jl:func:`Documenter.makedocs`"
    item2 = InventoryItem("`Documenter.makedocs`" => "lib/public/Documenter.makedocs")
    @test item != item2
    @test item2.name == item.name
    @test item2.domain == item.domain
    @test item2.role == "obj"
    item3 = InventoryItem(":func:`Documenter.makedocs`" => "lib/public/Documenter.makedocs")
    item4 =
        InventoryItem(":jl:func:`Documenter.makedocs`" => "lib/public/Documenter.makedocs")
    @test item == item3 == item4

    item = InventoryItem("main-index" => "#main-index"; dispname="Index", priority=2)
    @test item.name == "main-index"
    @test item.domain == "std"
    @test item.role == "label"
    @test item.priority == 2
    @test item.uri == "#\$"
    @test uri(item) == "#main-index"
    @test item.dispname == "Index"
    @test dispname(item) == "Index"
    item2 = InventoryItem("main index" => "#main-index"; dispname="Index", priority=2)
    @test item2 == item
    item3 = InventoryItem("main index" => "#main-index")
    @test item3 != item
    @test item3.name == "main-index"
    @test item3.dispname == "main index"
    @test dispname(item3) == "main index"
    @test item3.priority == -1

end


@testset "object recognition" begin

    item = InventoryItem(InventoryItem => "internals/#\$")
    @test spec(item) == ":jl:type:`DocInventories.InventoryItem`"
    @test uri(item) == "internals/#DocInventories.InventoryItem"

    item = InventoryItem(Dict => "base/collections/#Base.Dict")
    @test Dict isa UnionAll  # parametric type
    @test spec(item) == ":jl:type:`Base.Dict`"

    item = InventoryItem(filter => "internals/#\$")
    @test spec(item) == ":jl:func:`Base.filter`"

    item = InventoryItem(Documenter.Plugin => "lib/internals/writers/#\$")
    @test spec(item) == ":jl:abstract:`Documenter.Plugin`"

    docerror = getproperty(Documenter, Symbol("@docerror"))
    item = InventoryItem(docerror => "lib/internals/utilities/#Documenter.%40docerror")
    @test spec(item) == ":jl:macro:`Documenter.@docerror`"

    item = InventoryItem(Documenter => "lib/public/#\$")
    @test spec(item) == ":jl:mod:`Documenter`"

    item = InventoryItem("Index" => "index.html")
    @test spec(item) == ":std:label:`Index`"

    item = InventoryItem(":label:Index" => "index.html")
    @test spec(item) == ":std:label:`Index`"

    @test get_inventory_role("") == "obj"
    @test get_inventory_role(1) == "obj"

end

@testset "invalid IventoryItem" begin
    @test_throws ArgumentError begin
        InventoryItem(
            makedocs => "https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs"
        )
    end
end
