module ColorfulZz

using ColorTypes
using Colors: Colors, clamp01
using FixedPointNumbers

export LUTS, ColorTable, TabPseudoColor, ColorFunction, FunPseudoColor, ToPseudoColor, ColoredLabel


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


# 2. PSEUDO-COLORS DEFINED BY FUNCTIONS
# -------------------------------------

"""
    ColorFunction{R<:Function,G<:Function,B<:Function}

This type stores 3 functions producing red, green and blue channels.
"""
struct ColorFunction{R<:Function,G<:Function,B<:Function}
    red::R
    green::G
    blue::B
end

(c::ColorFunction)(C::Type{<:AbstractRGB}, val) = C(c.red(val), c.green(val), c.blue(val))

"""
    FunPseudoColor{T,F}

This type is used to render a real or gray value with a `ColorFunction`.
"""
struct FunPseudoColor{T,F} <: AbstractPseudoColor{T}
    val::T
end

# Traits from ColorTypes.jl
ColorTypes.red(c::FunPseudoColor{T,F})   where {T,F} = T(F.red(gray(c)))
ColorTypes.green(c::FunPseudoColor{T,F}) where {T,F} = T(F.green(gray(c)))
ColorTypes.blue(c::FunPseudoColor{T,F})  where {T,F} = T(F.blue(gray(c)))

# Defines conversion to RGB
Base.convert(C::Type{<:AbstractRGB}, c::FunPseudoColor{T,F}) where {T,F} = F(C, gray(c))

Base.eltype(::Type{FunPseudoColor{Gray{T},F}}) where {T,F} = T
Base.eltype(::Type{FunPseudoColor{T,F}}) where {T,F} = T

# 3. FUNCTOR
# -----------

"""
    ToPseudoColor{M}


"""
struct ToPseudoColor{M}
    map::M # ColorTable or ColorFunction
end

"""

"""
ToPseudoColor(name::Symbol) = ToPseudoColor(ColorTable(name))

"""

"""
ToPseudoColor(fred, fgreen, fblue) = ToPseudoColor(ColorFunction(fred, fgreen, fblue))

(f::ToPseudoColor{M})(img) where {M<:ColorTable} = reinterpret(reshape, TabPseudoColor{eltype(img), f.map}, img) #realtype(eltype(img))

(f::ToPseudoColor{M})(img) where {M<:ColorFunction} = reinterpret(reshape, FunPseudoColor{eltype(img), f.map}, img)

# Nice ToPseudoColor printing
function Base.show(io::IO, f::ToPseudoColor{M}) where M
    print(io, "ToPseudoColor{$M}(")
    print(io, f.map)
    print(io,")")
end


########################################################################################################################
#                                            SCALED GRAYS AND PSEUDO-COLORS                                            #
########################################################################################################################

# 1. SCALER
# ---------

"""
    Scaler{T}

This type automatically scales a real/gray value into the range [0-1].
"""
struct Scaler{T}
    low::T # lowest value
    rng::T # range of values
end

"""
    Scaler(::Type, lo, hi)

Builds a `Scaler` that scale a value from the range [lo-hi] to [0-1].
"""
Scaler(::Type{T}, lo, hi) where T = Scaler{T}(T(lo), T(hi - lo))

Scaler(::Type{Gray{T}}, lo, hi) where T = Scaler(T, lo, hi)

function (s::Scaler{T})(val::T) where T<:Normed
    # Computes in floating type to avoid overflow
    F = floattype(val)
    return T(clamp01((F(val) - F(s.low)) / F(s.rng)))
end

(s::Scaler{T})(val::T) where T<:Real = T((val - s.low) / s.rng)

(s::Scaler{T})(val::Gray{T}) where T = s(T(val))


# 2. SCALED GRAYS
# ---------------

struct ScaledGray{T,S} <: AbstractGray{T}
    val::T
end

ScaledGray(T, S, val) = ScaledGray{T,S}(val)

ColorTypes.gray(c::ScaledGray{T,S}) where {T,S} = S(c.val)

Base.convert(C::Type{<:AbstractRGB}, c::ScaledGray{T,S}) where {T,S} = C(gray(c))

Base.eltype(::Type{ScaledGray{T1}}) where {T2,T1<:Gray{T2}} = T2

# 3. SCALED PSEUDO-COLORS
# -----------------------

struct ScaledPseudoColor{T,C,S} <: AbstractPseudoColor{T}
  val::T
end

ScaledPseudoColor(T, C, S, val) = ScaledPseudoColor{T,C,S}(val)

# Traits from ColorTypes.jl
ColorTypes.gray(c::ScaledPseudoColor{T,C,S})  where {T,C,S} = S(c.val)
ColorTypes.red(c::ScaledPseudoColor{T,C,S})   where {T,C,S} = red(C(gray(c)))
ColorTypes.green(c::ScaledPseudoColor{T,C,S}) where {T,C,S} = green(C(gray(c)))
ColorTypes.blue(c::ScaledPseudoColor{T,C,S})  where {T,C,S} = blue(C(gray(c)))

# Defines conversion to RGB
Base.convert(C::Type{<:AbstractRGB}, c::ScaledPseudoColor) = C(red(c), green(c), blue(c))


# 4. FUNCTORS
# -----------

struct AutoMinMax end

function (f::AutoMinMax)(img::AbstractArray{T}) where T<:Union{Real,AbstractGray}
    return reinterpret(reshape, ScaledGray{eltype(img),_scaler_(img)}, img)
end

function (f::AutoMinMax)(img::AbstractArray{T1}) where T1<:AbstractPseudoColor
    T2 = eltype(eltype(img))
    return reinterpret(reshape, ScaledPseudoColor{T2,T1,_scaler_(img)}, img)
end

struct SetMinMax
    vmin # minimum value
    vmax # maximum value
end

function (f::SetMinMax)(img::AbstractArray{T}) where T<:Union{Real,AbstractGray}
    return reinterpret(reshape, ScaledGray{eltype(img),Scaler(eltype(img), f.vmin, f.vmax)}, img)
end

function (f::SetMinMax)(img::AbstractArray{T1}) where T1<:AbstractPseudoColor
    T2 = eltype(eltype(img))
    return reinterpret(reshape, ScaledPseudoColor{T2,T1,Scaler(eltype(img), f.vmin, f.vmax)}, img)
end

struct AutoSaturateMinMax
    qmin # first quantile
    qmax # last quantile
end

AutoSaturateMinMax(;qmin=0.05, qmax=0.95) = AutoSaturateMinMax(qmin, qmax)

function (f::AutoSaturateMinMax)(img::AbstractArray{T}) where T<:Union{Real,AbstractGray}
    return reinterpret(reshape, ScaledGray{eltype(img),_scaler_(img, f.qmin, f.qmax)}, img)
end

function (f::AutoSaturateMinMax)(img::AbstractArray{T1}) where T1<:AbstractPseudoColor
    T2 = eltype(eltype(img))
    return reinterpret(reshape, ScaledPseudoColor{T2,T1,_scaler_(gray.(img), f.qmin, f.qmax)}, value.(img))
end


# Internal helper functions:

function _scaler_(img)
    lo, hi = unsafe_extrema(img)
    return Scaler(eltype(img), lo, hi)
end

function _scaler_(img, qmin, qmax)
    lo, hi = quantile(img, (qmin, qmax))
    return Scaler(eltype(img), lo, hi)
end


########################################################################################################################
#                                                   LABELING COLORS                                                    #
########################################################################################################################

# 1. COLORED LABEL

struct ColoredLabel{I<:Unsigned,TAB,N} <: AbstractPseudoColor{I}
  lab::I
end

colored_label(tab::ColorTable, ::Type{T}=Unsigned) where T = ColoredLabel{T,tab,length(tab)}

label_color(tab::ColorTable, ::Type{T}=Unsigned) where T = LabelColor{T,tab,length(tab)}

ColorTypes.gray(c::ColoredLabel{I,TAB,N}) where {I,TAB,N} = c.lab / N

ColorTypes.red(c::ColoredLabel{T,TAB,N})   where {T,TAB,N} = _tabred_(TAB, gray(c))   # red(C, gray(c))
ColorTypes.green(c::ColoredLabel{T,TAB,N}) where {T,TAB,N} = _tabgreen_(TAB, gray(c)) # green(C, gray(c))
ColorTypes.blue(c::ColoredLabel{T,TAB,N})  where {T,TAB,N} = _tabblue_(TAB, gray(c))  # blue(C, gray(c))

ColorTypes.comp1(c::ColoredLabel) = red(c)
ColorTypes.comp2(c::ColoredLabel) = green(c)
ColorTypes.comp3(c::ColoredLabel) = blue(c)

Base.convert(C::Type{<:AbstractRGB}, c::ColoredLabel) = C(red(c), green(c), blue(c))

function Base.show(io::IO, ::Type{ColoredLabel{T,TAB,S}}) where {T,TAB,S}
  return print(io, "LabelColor{$T,ColorTable{$S,NTuple{$S,N0f8}(r,g,b),$S}")
end


# 2. LABELED GRAY



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

include("./luts/l_16_colors.jl")
include("./luts/l_3_3_2_rgb.jl")
include("./luts/l_5_ramps.jl")
include("./luts/l_6_shades.jl")
include("./luts/cyan_hot.jl")
include("./luts/green_fire_blue.jl")
include("./luts/hilo.jl")
include("./luts/ica.jl")
include("./luts/ica2.jl")
include("./luts/ica3.jl")
include("./luts/magenta_hot.jl")
include("./luts/orange_hot.jl")
include("./luts/rainbow_rgb.jl")
include("./luts/red_hot.jl")
include("./luts/thermal.jl")
include("./luts/yellow_hot.jl")
include("./luts/blue.jl")
include("./luts/blue_orange_icb.jl")
include("./luts/brgbcmyw.jl")
include("./luts/cool.jl")
include("./luts/cyan.jl")
include("./luts/edges.jl")
include("./luts/fire.jl")
include("./luts/gem.jl")
include("./luts/glasbey.jl")
include("./luts/glasbey_inverted.jl")
include("./luts/glasbey_on_dark.jl")
include("./luts/glow.jl")
include("./luts/grays.jl")
include("./luts/green.jl")
include("./luts/ice.jl")
include("./luts/magenta.jl")
include("./luts/mpl_inferno.jl")
include("./luts/mpl_magma.jl")
include("./luts/mpl_plasma.jl")
include("./luts/mpl_viridis.jl")
include("./luts/phase.jl")
include("./luts/physics.jl")
include("./luts/red_green.jl")
include("./luts/red.jl")
include("./luts/royal.jl")
include("./luts/sepia.jl")
include("./luts/smart.jl")
include("./luts/spectrum.jl")
include("./luts/thal.jl")
include("./luts/thallium.jl")
include("./luts/unionjack.jl")
include("./luts/yellow.jl")

end
