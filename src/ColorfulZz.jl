module ColorfulZz

using ColorTypes
using Colors: Colors, clamp01
using FixedPointNumbers

export LUTS, ColorTable, TabPseudoColor


########################################################################################################################
#                                              PSEUDO-COLOR ABSTRACT TYPE                                              #
########################################################################################################################

#=
To do :
- Define (?) arithmetic operators, by example :
    Base.:+(a::C) where C<:AbstractPseudoColor = C(+gray(a))
    Base.:-(a::C) where C<:AbstractPseudoColor = C(-gray(a))
    Base.:+(a::AbstractPseudoColor, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
    Base.:+(a::AbstractPseudoColor, b::Real) = Gray(gray(a) + gray(b))
    Base.:+(a::Real, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
    Base.:+(a::AbstractPseudoColor, b::Gray) = Gray(gray(a) + gray(b))
    Base.:+(a::Gray, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
- ComplexGray
=#

"""
This abstract type is used to define a pseudo-color (a.k.a. false-color) colorant rendered from a `Gray` colorant.
"""
abstract type AbstractPseudoColor{T} <: Color{T,3} end

"""
    value(a::AbstractPseudoColor{T})

Returns the raw value of a given pseudo-color.
"""
value(a::AbstractPseudoColor{T}) where T = reinterpret(T, a)

"""
    Base.eltype(::AbstractPseudoColor{T})
"""
Base.eltype(::AbstractPseudoColor{T}) where T = T

# Default traits from ColorTypes.jl
ColorTypes.gray(c::AbstractPseudoColor)  = c.val
ColorTypes.comp1(c::AbstractPseudoColor) = red(c)
ColorTypes.comp2(c::AbstractPseudoColor) = green(c)
ColorTypes.comp3(c::AbstractPseudoColor) = blue(c)
ColorTypes.color_type(::Type{AbstractPseudoColor{T}}) where T = Gray{T}


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
struct TabPseudoColor{T,TAB} <: AbstractPseudoColor{T}
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

# Nice printing (mostly for notebooks)
Base.show(io::IO, m::MIME"image/svg+xml", c::TabPseudoColor{T,TAB}) where {T,TAB} = (io, m, _tabcol_(TAB, c.val))


########################################################################################################################
#                                                    BUILT'IN LUTS                                                     #
########################################################################################################################

"""
A dictionnary containing all Look Up Tables distributed with ImageJ.

See also : [`ColorTable`](@ref)
"""
const LUTS = Dict()

function showluts()
    for (key, lut) in LUTS
        println(key)
        display(lut)
    end
end

include("./ijluts/l_16_colors.jl")
include("./ijluts/l_3_3_2_rgb.jl")
include("./ijluts/l_5_ramps.jl")
include("./ijluts/l_6_shades.jl")
include("./ijluts/cyan_hot.jl")
include("./ijluts/green_fire_blue.jl")
include("./ijluts/hilo.jl")
include("./ijluts/ica.jl")
include("./ijluts/ica2.jl")
include("./ijluts/ica3.jl")
include("./ijluts/magenta_hot.jl")
include("./ijluts/orange_hot.jl")
include("./ijluts/rainbow_rgb.jl")
include("./ijluts/red_hot.jl")
include("./ijluts/thermal.jl")
include("./ijluts/yellow_hot.jl")
include("./ijluts/blue.jl")
include("./ijluts/blue_orange_icb.jl")
include("./ijluts/brgbcmyw.jl")
include("./ijluts/cool.jl")
include("./ijluts/cyan.jl")
include("./ijluts/edges.jl")
include("./ijluts/fire.jl")
include("./ijluts/gem.jl")
include("./ijluts/glasbey.jl")
include("./ijluts/glasbey_inverted.jl")
include("./ijluts/glasbey_on_dark.jl")
include("./ijluts/glow.jl")
include("./ijluts/grays.jl")
include("./ijluts/green.jl")
include("./ijluts/ice.jl")
include("./ijluts/magenta.jl")
include("./ijluts/mpl_inferno.jl")
include("./ijluts/mpl_magma.jl")
include("./ijluts/mpl_plasma.jl")
include("./ijluts/mpl_viridis.jl")
include("./ijluts/phase.jl")
include("./ijluts/physics.jl")
include("./ijluts/red_green.jl")
include("./ijluts/red.jl")
include("./ijluts/royal.jl")
include("./ijluts/sepia.jl")
include("./ijluts/smart.jl")
include("./ijluts/spectrum.jl")
include("./ijluts/thal.jl")
include("./ijluts/thallium.jl")
include("./ijluts/unionjack.jl")
include("./ijluts/yellow.jl")

end
