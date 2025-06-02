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

function (s::Scaler{T})(val::Gray{T}) where T<:Normed
    # Computes in floating type to avoid overflow
    F = floattype(T)
    return Gray{T}(clamp01((F(val) - F(s.low)) / F(s.rng)))
end

(s::Scaler{T})(val::Gray{T}) where T<:Real = Gray{T}(clamp01((T(val) - T(s.low)) / T(s.rng)))

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

#Base.eltype(::Type{ScaledGray{T1}}) where {T2,T1<:Gray{T2}} = T2 # marche pas

# Nice ScaledGray printing
#Base.show(io::IO, c::ScaledGray{T,S}) where {T,S} = print(io, "ScaledGray{$T}($(gray(c)))")

# Nice printing (mostly for notebooks)
Base.show(io::IO, m::MIME"image/svg+xml", c::ScaledGray{T,S}) where {T,S} = show(io, m, gray(c))


# 3. SCALED PSEUDO-COLORS
# -----------------------

struct ScaledPseudoColor{T,C,S} <: AbstractColorful{T}
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

#Base.eltype(::Type{ScaledPseudoColor{T1}}) where {T2,T1<:Gray{T2}} = T2 # marche pas

# 4. FUNCTORS
# -----------

struct AutoMinMax end

function (f::AutoMinMax)(img::AbstractArray{T}) where T<:Union{Real,AbstractGray}
    return reinterpret(reshape, ScaledGray{eltype(img),_scaler_(img)}, img)
end

function (f::AutoMinMax)(img::AbstractArray{T1}) where T1<:AbstractColorful
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

function (f::SetMinMax)(img::AbstractArray{T1}) where T1<:AbstractColorful
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

function (f::AutoSaturateMinMax)(img::AbstractArray{T1}) where T1<:AbstractColorful # tester (img::AbstractArray{T1{T2}}) where {T1<:AbstractPseudoColor,T2}
    T2 = eltype(eltype(img))
    return reinterpret(reshape, ScaledPseudoColor{T2,T1,_scaler_(gray.(img), f.qmin, f.qmax)}, value.(img))
end


# Internal helper functions:

function _scaler_(img)
    lo, hi = fastextrema(img)
    return Scaler(eltype(img), lo, hi)
end

function _scaler_(img, qmin, qmax) # using Spipper pour virer les NaN ou missing
    lo, hi = quantile(img, (qmin, qmax)) #faire approximation avec histogramme pour plus rapide
    return Scaler(eltype(img), lo, hi)
end
