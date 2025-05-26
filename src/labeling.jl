########################################################################################################################
#                                                   LABELING COLORS                                                    #
########################################################################################################################

# 1. COLORED LABEL

struct ColoredLabel{I<:Unsigned,TAB,N} <: AbstractPseudoColor{I}
    lab::I
end

colored_label(tab::ColorTable, ::Type{T}=Unsigned) where T = ColoredLabel{T,tab,length(tab)}

colored_label(tab::Symbol, ::Type{T}=Unsigned) where T = colored_label(ColorTable(tab), T)

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

struct LabeledGray{T,L<:ColoredLabel,A} <: AbstractPseudoColor{T}
    val::T
    lab::L
end



ColorTypes.gray(c::LabeledGray{T,L,A}) where {T,L,A} = gray(c.val) #c.lab.lab > 0 : A * gray(c.lab) + gray(c.val) ?

ColorTypes.red(c::LabeledGray{T,L,A})   where {T,L,A} = _blend_(red, c) #!isbg(c) ? A * red(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.green(c::LabeledGray{T,L,A}) where {T,L,A} = _blend_(green, c) #!isbg(c) ? A * green(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.blue(c::LabeledGray{T,L,A})  where {T,L,A} = _blend_(blue, c) #!isbg(c) ? A * blue(c.lab) + (1 - A) * gray(c.val) : gray(c.val)

ColorTypes.comp1(c::LabeledGray) = red(c)
ColorTypes.comp2(c::LabeledGray) = green(c)
ColorTypes.comp3(c::LabeledGray) = blue(c)

Base.convert(C::Type{<:AbstractRGB}, c::LabeledGray) = C(red(c), green(c), blue(c))

_isbg_(c::ColoredLabel) = iszero(c.lab)
_isbg_(c::LabeledGray) = isbg(c.lab)
_blend_(col, c) = !_isbg_(c) ? A * col(c.lab) + (1 - A) * col(c.val) : col(c.val)
