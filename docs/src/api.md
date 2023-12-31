# API

The `DocInventories` package exports two names:

* [`Inventory`](@ref)
* [`InventoryItem`](@ref)

All other names should either be imported explicitly, e.g.,

```
using DocInventories: uri, spec
```

for [`uri`](@ref DocInventories.uri) and [`spec`](@ref DocInventories.spec), or used with the `DocInventories` prefix, e.g., [`DocInventories.save`](@ref).

---

```@autodocs
Modules = [DocInventories]
```
