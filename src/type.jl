########################################################################################################################
#                                              PSEUDO-COLOR ABSTRACT TYPE                                              #
########################################################################################################################

#=
To do :
- Define AlphaPseudoColor => soit alpha constant, soit alpha tabeau mm taille, soit alpha fonction de val
- Define (?) arithmetic operators, by example :
    Base.:+(a::C) where C<:AbstractPseudoColor = C(+gray(a))
    Base.:-(a::C) where C<:AbstractPseudoColor = C(-gray(a))
    Base.:+(a::AbstractPseudoColor, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
    Base.:+(a::AbstractPseudoColor, b::Real) = Gray(gray(a) + gray(b))
    Base.:+(a::Real, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
    Base.:+(a::AbstractPseudoColor, b::Gray) = Gray(gray(a) + gray(b))
    Base.:+(a::Gray, b::AbstractPseudoColor) = Gray(gray(a) + gray(b))
- AbstractPseudoColor => AbstractColorfulGray
- ComplexGray: module du complexe
- alpha compositing
- ThresholdedGray ThesholdedPseudoColor (lo, hi, over, under, over_under)
=#

"""
This abstract type is used to define a pseudo-color (a.k.a. false-color) colorant rendered from a `Gray` colorant.
"""
abstract type AbstractColorful{T} <: Color{T,3} end

"""
    value(a::AbstractColorful{T})

Returns the raw value of a given AbstractColorful type.
"""
value(a::AbstractColorful{T}) where T = reinterpret(T, a)

"""
    Base.eltype(::AbstractPseudoColor{T})
"""
Base.eltype(::AbstractColorful{T}) where T = T

# Default traits from ColorTypes.jl
ColorTypes.gray(c::AbstractColorful)  = c.val
ColorTypes.comp1(c::AbstractColorful) = red(c)
ColorTypes.comp2(c::AbstractColorful) = green(c)
ColorTypes.comp3(c::AbstractColorful) = blue(c)
ColorTypes.color_type(::Type{AbstractColorful{T}}) where T = Gray{T}
