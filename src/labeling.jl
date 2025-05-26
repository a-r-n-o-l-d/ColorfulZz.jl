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


