########################################################################################################################
#                                                    PSEUDO-COLORS                                                     #
########################################################################################################################

# 1. TABULATED PSEUDO-COLORS
# --------------------------

"""
    ColorTable{N,L<:NTuple{N,N0f8}}

This type is used to store a color table with `N` RGB colors (typically 256).
"""
struct ColorTable{N,L<:NTuple{N,N0f8}}
    r::L # red
    g::L # green
    b::L # blue
end

"""
    ColorTable(lut)

Builds a color table (a.k.a. look-up table) from a vector `lut` of colorant (as defined in ColorTypes.jl). `lut` could
be created with the package `ColorSchemes.jl` (see example below).

```@repl
using ColorSchemes
ColorTable(colorschemes[:jet])
```
"""
function ColorTable(lut)
    N = length(lut)
    r = Tuple(convert.(N0f8, red.(lut)))
    g = Tuple(convert.(N0f8, green.(lut)))
    b = Tuple(convert.(N0f8, blue.(lut)))
    ColorTable{N, NTuple{N,N0f8}}(r, g, b)
end

"""
    ColorTable(name)

Builds a color table (a.k.a. look-up table) from a symbol `name` refering to an entry in the dictionnary `LUTS`.

See also : [`LUTS`](@ref)
"""
ColorTable(name::Symbol) = LUTS[name]

# Internal helper functions:
## Convert a gray value to an index corresponding to a color in a ColorTable
_tabindex_(::ColorTable{N}, val) where N = round(Int, clamp01(val) * (N - 1) + 1)
_tabindex_(c::ColorTable, val::G) where {T,G<:AbstractGray{T}} = _tabindex_(c, T(val))
_tabindex_(c::ColorTable, val::G) where {T,G<:ScaledGray{<:AbstractGray{T}}} = _tabindex_(c, T(val)) # support for scaledgray
_tabindex_(::ColorTable{N}, val::Normed) where N = round(Int, val * (N - 1) + 1)
## Convert a gray value to a RGB color
function _tabcol_(c::ColorTable, val)
    i = _tabindex_(c, val)
    RGB(c.r[i], c.g[i], c.b[i])
end
## Convert a gray value to resp. red/green/blue component
_tabred_(c::ColorTable, val)   = c.r[_tabindex_(c, val)]
_tabgreen_(c::ColorTable, val) = c.g[_tabindex_(c, val)]
_tabblue_(c::ColorTable, val)  = c.b[_tabindex_(c, val)]

# Useful Base functions definition
Base.length(::ColorTable{N}) where N = N
Base.first(c::ColorTable) = RGB(first(c.r), first(c.g), first(c.b))
Base.last(c::ColorTable) = RGB(last(c.r), last(c.g), last(c.b))

# Nice and short printing
function Base.show(io::IO, c::ColorTable{N,L}) where {N,L}
    print(io, "ColorTable{$N,$L}(")
    print(io, RGB(first(c.r), first(c.g), first(c.b)))
    print(io, "...")
    print(io, RGB(last(c.r), last(c.g), last(c.b)))
    print(io, ")")
end

# Nice printing (mostly for notebooks)
Base.show(io::IO, m::MIME"image/svg+xml", c::ColorTable{N,L}) where {N,L} = show(io, m, collect(RGB.(c.r, c.g, c.b)))

"""
    TabPseudoColor{T<:Real,TAB} <: PseudoColor{T}

This type is used to render a real or gray value with a `ColorTable`.
"""
struct TabPseudoColor{T,TAB} <: AbstractColorful{T} #TabPseudoColorAlpha <: Color{T,3}
    val::T
end

# Traits from ColorTypes.jl
ColorTypes.red(c::TabPseudoColor{T,TAB})   where {T,TAB} = _tabred_(TAB, gray(c))
ColorTypes.green(c::TabPseudoColor{T,TAB}) where {T,TAB} = _tabgreen_(TAB, gray(c))
ColorTypes.blue(c::TabPseudoColor{T,TAB})  where {T,TAB} = _tabblue_(TAB, gray(c))

# Defines conversion to RGB
Base.convert(C::Type{<:AbstractRGB}, c::TabPseudoColor{T,TAB}) where {T,TAB} = C(_tabcol_(TAB, gray(c)))

Base.eltype(::Type{TabPseudoColor{Gray{T},TAB}}) where {T,TAB} = T
Base.eltype(::Type{TabPseudoColor{T,TAB}}) where {T,TAB} = T

# Defines the way TabPseudoColor type is printed (its more concise than default)
function Base.show(io::IO, ::Type{TabPseudoColor{T,TAB}}) where {T,TAB}
    tab = "($(first(TAB))...$(last(TAB)))"
    print(io, "TabPseudoColor{$T,$tab}")
end

# Nice TabPseudoColor printing
Base.show(io::IO, c::TabPseudoColor{T,TAB}) where {T,TAB} = print(io, "TabPseudoColor{$T}($(gray(c)))")

# Nice printing (mostly for notebooks) marche pas
Base.show(io::IO, m::MIME"image/svg+xml", c::TabPseudoColor{T,TAB}) where {T,TAB} = show(io, m, _tabcol_(TAB, c.val))


# 2. PSEUDO-COLORS DEFINED BY FUNCTIONS
# -------------------------------------

# To do definir les Base.show

"""
    ColorFunction{R<:Function,G<:Function,B<:Function}

This type stores 3 functions producing red, green and blue channels.
"""
struct ColorFunction{R<:Function,G<:Function,B<:Function} #ColorFunctionAlpha ???
    red::R
    green::G
    blue::B
end

(c::ColorFunction)(C::Type{<:AbstractRGB}, val) = C(c.red(val), c.green(val), c.blue(val))

"""
    FunPseudoColor{T,F}

This type is used to render a real or gray value with a `ColorFunction`.
"""
struct FunPseudoColor{T,F} <: AbstractColorful{T}
    val::T
end

# Traits from ColorTypes.jl
ColorTypes.red(c::FunPseudoColor{T,F})   where {T,F} = T(F.red(gray(c)))
ColorTypes.green(c::FunPseudoColor{T,F}) where {T,F} = T(F.green(gray(c)))
ColorTypes.blue(c::FunPseudoColor{T,F})  where {T,F} = T(F.blue(gray(c)))

# Defines conversion to RGB
Base.convert(C::Type{<:AbstractRGB}, c::FunPseudoColor{T,F}) where {T,F} = F(C, gray(c))

Base.eltype(::Type{FunPseudoColor{Gray{T},F}}) where {T,F} = T #tester
Base.eltype(::Type{FunPseudoColor{T,F}}) where {T,F} = T #tester

# 3. FUNCTOR
# -----------

"""
    AsPseudoColor{M}


"""
struct AsPseudoColor{M}
    map::M # ColorTable or ColorFunction
end

"""

"""
AsPseudoColor(name::Symbol) = AsPseudoColor(ColorTable(name)) # ajout recherche ij et colorschemes auto

"""

"""
AsPseudoColor(fred, fgreen, fblue) = AsPseudoColor(ColorFunction(fred, fgreen, fblue))

(f::AsPseudoColor{M})(img) where M<:ColorTable = reinterpret(reshape, TabPseudoColor{eltype(img), f.map}, img) #realtype(eltype(img)) ::AbstractArray{T} ,T<:Union{Number,AbstractGray}

function (f::AsPseudoColor{M})(img::AbstractArray{TG}) where {M<:ColorTable, TG<:TransparentGray}
    # Discard alpha channel
    G = base_color_type(color_type(eltype(img)))
    N = eltype(color_type(eltype(img)))
    mimg = mappedarray(G{N}, img)
    PC = TabPseudoColor{eltype(mimg), f.map}
    return reinterpret(reshape, PC, mimg)
end

(f::AsPseudoColor{M})(img) where {M<:ColorFunction} = reinterpret(reshape, FunPseudoColor{eltype(img), f.map}, img)

# Nice AsPseudoColor printing
function Base.show(io::IO, f::AsPseudoColor{M}) where M
    print(io, "AsPseudoColor{$M}(")
    print(io, f.map)
    print(io,")")
end
