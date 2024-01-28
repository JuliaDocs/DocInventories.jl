using Test
using TestingUtilities: @Test
using DocInventories: InventoryItem, uri, dispname, spec, show_full
using Documenter: Documenter, makedocs
using IOCapture: IOCapture


@testset "InventoryItem" begin

    item = InventoryItem(name="Documenter.makedocs", role="function", uri="lib/public/#\$")
    @test item.domain == "jl"
    @test item.dispname == "-"
    @Test repr(item) ==
          "InventoryItem(\":jl:function:`Documenter.makedocs`\" => \"lib/public/#\\\$\")"
    @Test repr("text/plain", item) == repr(item)
    @Test repr(item; context=(:full => true)) ==
          "InventoryItem(name=\"Documenter.makedocs\", domain=\"jl\", role=\"function\", priority=1, uri=\"lib/public/#Documenter.makedocs\", dispname=\"Documenter.makedocs\")"
    @test item.uri == "lib/public/#\$"
    @test uri(item) == "lib/public/#Documenter.makedocs"
    @test dispname(item) == "Documenter.makedocs"
    @test spec(item) == ":jl:function:`Documenter.makedocs`"
    item2 = InventoryItem(":obj:`Documenter.makedocs`" => "lib/public/#Documenter.makedocs")
    @test item != item2  # different role
    @test item2.name == item.name
    @test item2.domain == item.domain
    @test item2.role == "obj"
    item3 = InventoryItem(
        ":function:`Documenter.makedocs`" => "lib/public/#Documenter.makedocs"
    )
    item4 = InventoryItem(
        ":jl:function:`Documenter.makedocs`" => "lib/public/#Documenter.makedocs"
    )
    item5 =  # leading slash in `uri` should be stripped
        InventoryItem(name="Documenter.makedocs", role="function", uri="/lib/public/#\$")
    item6 =  # name in `uri` should be normalized
        InventoryItem(
            name="Documenter.makedocs",
            role="function",
            uri="/lib/public/#Documenter.makedocs"
        )
    @test item == item3 == item4 == item5 == item6

    item = InventoryItem("main-index" => "#main-index"; dispname="Index", priority=2)
    @test item.name == "main-index"
    @test item.domain == "std"
    @test item.role == "label"
    @test item.priority == 2
    @test item.uri == "#\$"
    @test uri(item) == "#main-index"
    @test item.dispname == "Index"
    @test dispname(item) == "Index"
    expected_repr = raw"""
    InventoryItem(
      ":std:label:`main-index`" => "#\$",
      priority=2,
      dispname="Index"
    )
    """
    @Test repr("text/plain", item) == chop(expected_repr)
    expected_full_repr = raw"""
    InventoryItem(
      name="main-index",
      domain="std",
      role="label",
      priority=2,
      uri="#main-index",
      dispname="Index"
    )
    """
    @Test repr("text/plain", item; context=(:full => true)) == chop(expected_full_repr)
    c = IOCapture.capture() do
        show_full(item)
    end
    @Test c.output == chop(expected_full_repr)
    item2 = InventoryItem("main index" => "#main-index"; dispname="Index", priority=2)
    @test item2 == item
    item3 = InventoryItem("main index" => "#main-index")
    @test item3 != item
    @test item3.name == "main-index"
    @test item3.dispname == "main index"
    @test dispname(item3) == "main index"
    @test item3.priority == -1

    item = InventoryItem(":doc:index" => ""; dispname="Index")
    @test item.domain == "std"
    @test item.role == "doc"
    @test item.name == "index"
    @test item.dispname == "Index"

end


@testset "IventoryItem on 32-bit" begin
    item = InventoryItem("f" => "#f"; priority=Int32(1))
    @test item.priority == 1
    item = InventoryItem("f" => "#f"; priority=Int64(1))
    @test item.priority == 1
    item = InventoryItem("f" => "#f"; priority=UInt8(1))
    @test item.priority == 1
    item = InventoryItem("f" => "#f"; priority=Int8(1))
    @test item.priority == 1
    item = InventoryItem("f" => "#f"; priority=1)
    @test item.priority == 1
end


@testset "invalid IventoryItem" begin
    @test_throws ArgumentError begin
        InventoryItem(
            "`makedocs`" => "https://documenter.juliadocs.org/stable/lib/public/#Documenter.makedocs"
        )
    end
end
