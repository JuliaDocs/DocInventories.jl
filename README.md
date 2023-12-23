# DocInventories.jl

[DocInventories.jl](https://github.com/JuliaDocs/DocInventories.jl#readme) is a package for reading and writing inventory files such as the `objects.inv` file used by [InterSphinx](https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html).

## Usage

```julia
julia> using DocInventories

julia> inventory = Inventory("https://matplotlib.org/3.7.3/objects.inv")
# Sphinx inventory version 2
# Project: Matplotlib
# Version: 3.7.3
# The remainder of this file would be compressed using zlib.
2dcollections3d std:label -1 tutorials/toolkits/mplot3d.html#dcollections3d 2D plots in 3D
3d_plots std:label -1 plot_types/3D/index.html#d-plots 3D
HOME std:envvar 1 users/faq/environment_variables_faq.html#envvar-$ -
…

julia> inventory["matplotlib.pyplot.subplots"]  # spec lookup
InventoryItem(":py:function:`matplotlib.pyplot.subplots`" => "api/_as_gen/matplotlib.pyplot.subplots.html#\$")

julia> inventory(r":py:function:.*\.subplots?`")  # free-form search
2-element Vector{DocInventories.InventoryItem}:
 InventoryItem(":py:function:`matplotlib.pyplot.subplot`" => "api/_as_gen/matplotlib.pyplot.subplot.html#\$")
 InventoryItem(":py:function:`matplotlib.pyplot.subplots`" => "api/_as_gen/matplotlib.pyplot.subplots.html#\$")

julia> inventory("tutorials/introductory/quick_start.html#figure-parts")  # uri search
1-element Vector{DocInventories.InventoryItem}:
 InventoryItem(":std:label:`figure_parts`" => "tutorials/introductory/quick_start.html#figure-parts", priority=-1, dispname="Parts of a Figure")

julia> write("objects.inv", inventory)  # compressed file

julia> write("objects.txt", repr("text/plain", inventory))  # uncompressed
```
