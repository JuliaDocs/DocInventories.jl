using Test
using TestingUtilities: @Test
using DocInventories
using DocInventories: uri, spec, find_in_inventory, split_url, show_full
using DocInventories: InventoryFormatError
using Downloads: RequestError
using IOCapture: IOCapture


@testset "Read quantumpropagators.inv" begin

    inventory = Inventory(
        joinpath(@__DIR__, "quantumpropagators.inv");
        root_url="https://juliaquantumcontrol.github.io/QuantumPropagators.jl/stable/"
    )
    @test inventory.project == "QuantumPropagators.jl"
    m = match(r"^Inventory\(\"[^\"]+\"; root_url=\"[^\"]+\"\)$", repr(inventory))
    @test !isnothing(m)
    @test length(inventory("Storage")) == 6

end

@testset "Read krotov.inv" begin

    inventory = Inventory(
        joinpath(@__DIR__, "krotov.inv");
        root_url="https://qucontrol.github.io/krotov/v1.2.1/"
    )
    @test inventory.project == "Krotov"
    @test inventory.version == "1.2.1"
    default_repl_repr = repr("text/plain", inventory; context=(:limit => true))
    @Test default_repl_repr == raw"""
    Inventory(
     project="Krotov",
     version="1.2.1",
     root_url="https://qucontrol.github.io/krotov/v1.2.1/",
     items=[
      InventoryItem(":std:label:`/01_overview.rst`" => "01_overview.html", dispname="Krotov Python Package"),
      InventoryItem(":std:label:`/01_overview.rst#citing-the-krotov-package`" => "01_overview.html#citing-the-krotov-package", dispname="Citing the Krotov Package"),
      InventoryItem(":std:label:`/01_overview.rst#installation`" => "01_overview.html#installation", dispname="Installation"),
      InventoryItem(":std:label:`/01_overview.rst#krotov-python-package`" => "01_overview.html#krotov-python-package", dispname="Krotov Python Package"),
      InventoryItem(":std:label:`/01_overview.rst#prerequisites`" => "01_overview.html#prerequisites", dispname="Prerequisites"),
      ⋮ (507 elements in total)
      InventoryItem(":std:label:`py-modindex`" => "py-modindex.html", dispname="Python Module Index"),
      InventoryItem(":std:label:`search`" => "search.html", dispname="Search Page"),
      InventoryItem(":std:label:`secondorderupdate`" => "07_krotovs_method.html#\$", dispname="Second order update"),
      InventoryItem(":std:label:`timediscretization`" => "07_krotovs_method.html#\$", dispname="Time discretization"),
      InventoryItem(":std:label:`using-krotov-with-qutip`" => "08_qutip_usage.html#\$", dispname="Using Krotov with QuTiP"),
      InventoryItem(":std:label:`write-documentation`" => "02_contributing.html#\$", dispname="Write Documentation"),
     ]
    )
    """

    c = IOCapture.capture() do
        show_full(inventory)
    end
    @test length(c.output) > 50_000

    try
        inventory = Inventory("https://qucontrol.github.io/krotov/v1.2.1/objects.inv")
        @test inventory.project == "Krotov"
        @test inventory.root_url == "https://qucontrol.github.io/krotov/v1.2.1/"
        @test startswith(uri(inventory, spec(inventory[1])), inventory.root_url)
        fig_label = inventory[":std:label:`figoctdecisiontree`"].dispname
        @test length(split(fig_label, "\n")) > 10
        # It's unusual for a `dispname` to span multiple lines, but it does
        # happen "in the wild" (as this example demonstrates). We're making
        # sure that we can properly parse inventories with such extra lines.
        # Other libraries (https://github.com/bskinn/sphobjinv) do not!
    catch exception
        @warn "Cannot read online inventory in test" exception
    end

end


@testset "Read invalid" begin

    @test_throws RequestError begin
        Inventory("http://noexist.michaelgoerz.net/ojects.inv"; timeout=0.01, retries=1)
    end

    url = "ftp://qucontrol.github.io/krotov/v1.2.1/objects.inv"
    @test_throws ArgumentError begin
        split_url(url)
    end
    @test_throws SystemError begin
        Inventory(url; root_url="")
    end

    mktempdir() do tempdir

        filename = joinpath(tempdir, "does_not_exist.inv")
        @test_throws SystemError begin
            Inventory(filename; root_url="")
        end

        filename = joinpath(tempdir, "does_not_exist.unknown")
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="")
        end
        @test c.value isa ArgumentError
        @test contains(c.output, "Cannot determine MIME type")

        filename = joinpath(tempdir, "sometext.txt")
        #!format: off
        write(filename, """
        # This is a text file that is not a Sphinx inventory.
        """)
        #!format: on
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename)
        end
        @test c.value isa InventoryFormatError
        @test contains(c.output, "Empty root url")
        @test contains(
            c.output,
            "Invalid Sphinx header line. Must be \"# Sphinx inventory version 2\""
        )
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="", mime="application/toml")
        end
        @test contains(c.output, "Invalid TOML inventory")

        filename = joinpath(tempdir, "incomplete.txt")
        #!format: off
        write(filename, """
        # Sphinx inventory version 2
        """)
        #!format: on
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="")
        end
        @test c.value isa InventoryFormatError
        @test contains(c.output, "Invalid project name line")

        filename = joinpath(tempdir, "invalid_version.txt")
        #!format: off
        write(filename, """
        # Sphinx inventory version 2
        # Project: Test
        # Version 1.0
        """)
        #!format: on
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="")
        end
        @test c.value isa InventoryFormatError
        @test contains(c.output, "Invalid project version line")

        filename = joinpath(tempdir, "invalid_compression_line.txt")
        #!format: off
        write(filename, """
        # Sphinx inventory version 2
        # Project: Test
        # Version: 1.0
        # This is not a valid compression line
        """)
        #!format: on
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="")
        end
        @test c.value isa InventoryFormatError
        @test contains(c.output, "Invalid compression line")

        filename = joinpath(tempdir, "invalid_data.txt")
        #!format: off
        write(filename, """
        # Sphinx inventory version 2
        # Project: Test
        # Version: 1.0
        # The remainder of this file would be compressed using zlib.
        This is just
        a bunch of text,
        but no valid InventoryItem data
        """)
        #!format: on
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="")
        end
        @test c.value isa InventoryFormatError
        @test contains(c.output, "Unexpected line")

    end

end

@testset "Empty inventory" begin

    mktempdir() do tempdir

        empty = Inventory(project="empty")
        @test isempty(empty)
        filename = joinpath(tempdir, "empty.inv")
        DocInventories.save(filename, empty)
        @test contains(read(filename, String), "# This file is empty")
        empty = Inventory(filename; root_url="")
        @test isempty(empty)

        filename = joinpath(tempdir, "empty.txt")
        DocInventories.save(filename, empty)
        @test contains(read(filename, String), "# This file is empty")
        empty = Inventory(filename; root_url="")
        @test isempty(empty)

        filename = joinpath(tempdir, "empty.toml")
        DocInventories.save(filename, empty)
        empty = Inventory(filename; root_url="")
        @test isempty(empty)

    end

end


@testset "Iventory property names" begin
    inventory = Inventory(project="N/A")
    @test propertynames(inventory) isa Tuple
    @test propertynames(inventory, true) isa Tuple
    @test !(:_items in propertynames(inventory))
    @test (:_items in propertynames(inventory, true))
end


@testset "Build inventory manually" begin
    inventory = Inventory(project="WP", root_url="https://en.wikipedia.org/wiki/")
    push!(
        inventory,
        InventoryItem("Sphinx" => "Sphinx_(documentation_generator)"),
        InventoryItem("reStructuredText" => "ReStructuredText")
    )
    @Test repr(inventory) ==
          "Inventory(\"WP\", \"\", InventoryItem[InventoryItem(\":std:label:`Sphinx`\" => \"Sphinx_(documentation_generator)\"), InventoryItem(\":std:label:`reStructuredText`\" => \"ReStructuredText\")], \"https://en.wikipedia.org/wiki/\", \"\", false)"
    @Test repr("text/plain", inventory) ==
          "Inventory(\n project=\"WP\",\n version=\"\",\n root_url=\"https://en.wikipedia.org/wiki/\",\n items=[\n  InventoryItem(\":std:label:`Sphinx`\" => \"Sphinx_(documentation_generator)\"),\n  InventoryItem(\":std:label:`reStructuredText`\" => \"ReStructuredText\"),\n ]\n)\n"
    append!(
        inventory,
        [
            InventoryItem(
                "Lightweight markup languages" => "Category:Lightweight_markup_languages"
            ),
            InventoryItem("Markup languages" => "Category:Markup_languages")
        ],
        [
            InventoryItem("Julia" => "Julia_(programming_language)"),
            InventoryItem("Python" => "Python_(programming_language)")
        ],
    )
    @test !inventory.sorted
    @test inventory.source == ""
    @test inventory.root_url == "https://en.wikipedia.org/wiki/"
    @test inventory[begin].name == "Sphinx"
    @test inventory[end].name == "Python"
    items_with_parenthesis = inventory(r"uri=.*\(.*\)")
    @test length(items_with_parenthesis) == 3
    _inventory = sort(inventory)
    @test _inventory.sorted
    @test sort(_inventory).sorted
    mktempdir() do tempdir
        filename = joinpath(tempdir, "objects.inv")
        DocInventories.save(filename, inventory)
        inventory = Inventory(filename; root_url="https://en.wikipedia.org/wiki/")
    end
    @test inventory.sorted
    @test inventory.project == "WP"
    @test inventory.root_url == "https://en.wikipedia.org/wiki/"
    @test endswith(inventory.source, "/objects.inv")
    @test inventory.version == ""
    @test length(inventory) == 6
    @test inventory[1].name == "Julia"
    @test spec(inventory[1]) == ":std:label:`Julia`"
    @Test uri(inventory["Julia"]; root_url=inventory.root_url) ==
          "https://en.wikipedia.org/wiki/Julia_(programming_language)"
    @Test uri(inventory, "Julia") ==
          "https://en.wikipedia.org/wiki/Julia_(programming_language)"
    items_with_parenthesis = inventory(r"uri=.*\(.*\)")
    @test length(items_with_parenthesis) == 3
    inventory = sort(
        Inventory(
            project=inventory.project,
            version=inventory.version,
            root_url=inventory.root_url,
            items=filter(it -> startswith(it.uri, "Category"), collect(inventory))
        )
    )
    @test length(inventory) == 2
    @test inventory.source == ""
    @test inventory.sorted
    @test spec(inventory[1]) == ":std:label:`Lightweight-markup-languages`"
    append!(
        inventory,
        [
            InventoryItem("Julia" => "Julia_(programming_language)"),
            InventoryItem("Python" => "Python_(programming_language)")
        ]
    )
    @test length(inventory) == 4
    @test spec(inventory[1]) == ":std:label:`Julia`"

end


@testset "Search inventory" begin

    inventory = Inventory(project="Search", version="1.0")
    push!(
        inventory,
        InventoryItem(":foo:a:`A`" => "#\$"; priority=-1),
        InventoryItem(":foo:b:`A`" => "#\$"; priority=0),
        InventoryItem(":foo:c:`A`" => "#\$"; priority=1),
        InventoryItem(":foo:a:`B`" => "#\$"; priority=1),
        InventoryItem(":foo:a:`C`" => "#\$"; priority=1),
        InventoryItem(":bar:a:`A`" => "#\$"; priority=2),
        InventoryItem(":bar:b:`A`" => "#\$"; priority=0),
        InventoryItem(":bar:c:`A`" => "#\$"; priority=-1),
    )
    expected = raw"""
    Inventory(
     project="Search",
     version="1.0",
     root_url="",
     items=[
      InventoryItem(":foo:a:`A`" => "#\$", priority=-1),
      InventoryItem(":foo:b:`A`" => "#\$", priority=0),
      InventoryItem(":foo:c:`A`" => "#\$"),
      InventoryItem(":foo:a:`B`" => "#\$"),
      InventoryItem(":foo:a:`C`" => "#\$"),
      InventoryItem(":bar:a:`A`" => "#\$", priority=2),
      InventoryItem(":bar:b:`A`" => "#\$", priority=0),
      InventoryItem(":bar:c:`A`" => "#\$", priority=-1),
     ]
    )
    """
    @Test repr("text/plain", inventory) == expected
    @test !inventory.sorted

    found = inventory("`A`")
    @test length(found) == 6
    @test found[begin].priority == 0
    @test found[end].priority == 2

    found = inventory("`A`"; include_hidden_priority=false)
    @test length(found) == 4
    @test found[begin].priority == 0
    @test found[end].priority == 2

    found = inventory(":foo:")
    @test length(found) == 5
    @test found[begin].priority == 0
    @test any([it.priority == -1 for it in found[2:end]])

    c = IOCapture.capture() do
        find_in_inventory(inventory, "A")
    end
    @test c.value == inventory["A"]
    @test c.value.priority == 0
    @test contains(c.output, "Warning: Ambiguous search")

    c = IOCapture.capture() do
        find_in_inventory(inventory, "A"; quiet=true)
    end
    @test !contains(c.output, "Warning: Ambiguous search")

    @test isnothing(inventory["D"])
    c = IOCapture.capture() do
        find_in_inventory(inventory, "D")
    end
    @test isnothing(c.value)
    @test contains(c.output, "Error: Cannot find item")
    c = IOCapture.capture() do
        find_in_inventory(inventory, "D"; quiet=true)
    end
    @test !contains(c.output, "Cannot find item")

    found = find_in_inventory(inventory, "A"; domain="foo", quiet=true)
    @test found == inventory[":foo:b:`A`"]
    found = find_in_inventory(inventory, "A"; domain="foo", role="c", quiet=true)
    @test found == inventory[":foo:c:`A`"]
    found = find_in_inventory(
        inventory,
        "A";
        domain="foo",
        role="a",
        include_hidden_priority=false,
        quiet=true
    )
    @test isnothing(found)

end


@testset "Inventory I/O" begin

    inventory = Inventory(project="IOTest", version="1.0")

    push!(
        inventory,
        InventoryItem(":jl:func:`a`" => "#\$"),
        InventoryItem(":jl:type:`A`" => "#\$"),
        InventoryItem(":std:label:`Introduction`" => "#\$"),
        InventoryItem(":std:label:`section-2`" => "#\$", dispname="Section 2"),
    )
    @test length(inventory) == 4
    @test !inventory.sorted

    mktempdir() do tempdir

        filename = joinpath(tempdir, "objects.inv")
        DocInventories.save(filename, inventory)  # auto-mime
        readinv = Inventory(filename; root_url="")
        @test length(readinv) == 4
        @test readinv.sorted
        readinv = Inventory(filename; root_url="", mime="application/x-intersphinx")
        @test length(readinv) == 4
        @test readinv.sorted
        @test readinv[":std:label:`Introduction`"].priority == -1
        @test readinv[":jl:func:`a`"].priority == 1
        @test readinv[":std:label:`section-2`"].dispname == "Section 2"

        filename = joinpath(tempdir, "objects.txt")  # inappropriate extension
        DocInventories.save(filename, inventory, "application/x-intersphinx")
        readinv = Inventory(filename; root_url="", mime="application/x-intersphinx")
        @test length(readinv) == 4

        filename = joinpath(tempdir, "objects.txt")
        DocInventories.save(filename, inventory)  # auto-mime
        readinv = Inventory(filename; root_url="", mime="text/x-intersphinx")
        @test length(readinv) == 4

        filename = joinpath(tempdir, "objects.toml")
        DocInventories.save(filename, inventory)  # auto-mime
        readinv = Inventory(filename; root_url="", mime="application/toml")
        @test length(readinv) == 4

        filename = joinpath(tempdir, "objects.inv")  # inappropriate extension
        DocInventories.save(filename, inventory, "text/x-intersphinx")
        readinv = Inventory(filename; root_url="", mime="text/x-intersphinx")
        @test length(readinv) == 4

        filename = joinpath(tempdir, "objects.txt")  # inappropriate extension
        DocInventories.save(filename, inventory, "application/toml")
        readinv = Inventory(filename; root_url="", mime="application/toml")
        @test length(readinv) == 4
        @test readinv[":std:label:`Introduction`"].priority == -1
        @test readinv[":jl:func:`a`"].priority == 1
        @test readinv[":std:label:`section-2`"].dispname == "Section 2"

        filename = joinpath(tempdir, "objects.txt.gz")
        DocInventories.save(filename, inventory)
        readinv = Inventory(filename; root_url="")
        @test length(readinv) == 4

        filename = joinpath(tempdir, "objects.toml.gz")
        DocInventories.save(filename, inventory)
        readinv = Inventory(filename; root_url="")
        @test length(readinv) == 4

        filename = tempname(tempdir; cleanup=false)
        c = IOCapture.capture(rethrow=Union{}) do
            DocInventories.save(filename, inventory, "application/x-invalid")
        end
        @test c.value isa MethodError
        @test contains(c.output, "requires the following")

        filename = joinpath(tempdir, "objects.inv")
        DocInventories.save(filename, inventory)
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="", mime="application/x-invalid")
        end
        @test contains(c.output, "requires the following")
        @test contains(c.output, "Invalid mime format application/x-invalid.")
        @test c.value isa ArgumentError
        if c.value isa ArgumentError
            @test contains(c.value.msg, "Invalid source/mime for loading Inventory")
        end

        filename = joinpath(tempdir, "objects.txt.gz")
        DocInventories.save(filename, inventory, "text/x-intersphinx+gzip")
        c = IOCapture.capture(rethrow=Union{}) do
            Inventory(filename; root_url="", mime="text/x-intersphinx")
        end
        @test contains(c.output, "Only v2 objects.inv files currently supported")
        @test c.value isa InventoryFormatError

    end

end
