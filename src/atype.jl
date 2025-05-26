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
- ComplexGray: module du complexe
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
