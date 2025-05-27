########################################################################################################################
#                                                   LABELING COLORS                                                    #
########################################################################################################################

# 1. COLORED LABEL
# ----------------
struct ColoredLabel{T,TAB} <: AbstractPseudoColor{T} #<:Unsigned
    lab::T
end

colored_label(tab::ColorTable, ::Type{T}=Unsigned) where T = ColoredLabel{T,tab,length(tab)}

colored_label(tab::Symbol, ::Type{T}=Unsigned) where T = colored_label(ColorTable(tab), T)

ColorTypes.gray(c::ColoredLabel{I,TAB}) where {I,TAB} = c.lab / length(TAB)

ColorTypes.red(c::ColoredLabel{T,TAB})   where {T,TAB} = _tabred_(TAB, gray(c))   # red(C, gray(c))
ColorTypes.green(c::ColoredLabel{T,TAB}) where {T,TAB} = _tabgreen_(TAB, gray(c)) # green(C, gray(c))
ColorTypes.blue(c::ColoredLabel{T,TAB})  where {T,TAB} = _tabblue_(TAB, gray(c))  # blue(C, gray(c))

ColorTypes.comp1(c::ColoredLabel) = red(c)
ColorTypes.comp2(c::ColoredLabel) = green(c)
ColorTypes.comp3(c::ColoredLabel) = blue(c)

Base.convert(C::Type{<:AbstractRGB}, c::ColoredLabel) = C(red(c), green(c), blue(c))

function Base.show(io::IO, ::Type{ColoredLabel{T,TAB}}) where {T,TAB}
    return print(io, "ColoredLabel{$T,$TAB}")
end


# 2. LABELED GRAYS
# ----------------

struct LabeledGray{T,A} <: AbstractPseudoColor{T}
    val::T
    lab
end

ColorTypes.gray(c::LabeledGray) = gray(c.val) #c.lab.lab > 0 : A * gray(c.lab) + gray(c.val) ?

ColorTypes.red(c::LabeledGray)   = _blend_(red, c) #!isbg(c) ? A * red(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.green(c::LabeledGray) = _blend_(green, c) #!isbg(c) ? A * green(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.blue(c::LabeledGray)  = _blend_(blue, c) #!isbg(c) ? A * blue(c.lab) + (1 - A) * gray(c.val) : gray(c.val)

ColorTypes.comp1(c::LabeledGray) = red(c)
ColorTypes.comp2(c::LabeledGray) = green(c)
ColorTypes.comp3(c::LabeledGray) = blue(c)

Base.convert(C::Type{<:AbstractRGB}, c::LabeledGray) = C(red(c), green(c), blue(c))


# 3. LABELED PSEUDO-COLORS
# ------------------------

struct LabeledPseudoColor{T,A} <: AbstractPseudoColor{T}
    val::T
    lab
end

ColorTypes.gray(c::LabeledPseudoColor) = gray(c.val)

ColorTypes.red(c::LabeledPseudoColor)   = _blend_(red, c) #!isbg(c) ? A * red(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.green(c::LabeledPseudoColor) = _blend_(green, c) #!isbg(c) ? A * green(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
ColorTypes.blue(c::LabeledPseudoColor)  = _blend_(blue, c) #!isbg(c) ? A * blue(c.lab) + (1 - A) * gray(c.val) : gray(c.val)

ColorTypes.comp1(c::LabeledPseudoColor) = red(c)
ColorTypes.comp2(c::LabeledPseudoColor) = green(c)
ColorTypes.comp3(c::LabeledPseudoColor) = blue(c)

Base.convert(C::Type{<:AbstractRGB}, c::LabeledPseudoColor) = C(red(c), green(c), blue(c))


# 4. FUNCTORS
# -----------

struct AsColoredLabeling
    tab
end

AsColoredLabeling(tab::Symbol=:glasbey_inverted) = AsColoredLabeling(ColorTable(tab))

(l::AsColoredLabeling)(img::AbstractArray{T}) where T = reinterpret(reshape, ColoredLabel{T,l.tab}, img)

struct OverlayLabels
    tab
    alpha
end

OverlayLabels(tab::Symbol=:glasbey_inverted, alpha=0.6) = OverlayLabels(ColorTable(tab), alpha)

function (o::OverlayLabels)(img::AbstractArray{T1}, labs::AbstractArray{T2}) where {T1,T2<:ColoredLabel}
    #cl = ColoredLabel{T2,o.tab}
    lg = LabeledGray{T1,o.alpha}
    return mappedarray(lg, img, labs)
end

function (o::OverlayLabels)(img::AbstractArray{T1}, labs::AbstractArray{T2}) where {T1,T2}
    la = reinterpret(reshape, ColoredLabel{T2,o.tab}, labs)
    lg = LabeledGray{T1,o.alpha}
    return mappedarray(lg, img, la)
end

function (o::OverlayLabels)(img::AbstractArray{T1}, labs::AbstractArray{T2}) where {T1<:AbstractPseudoColor,T2<:ColoredLabel}
    #cl = ColoredLabel{T2,o.tab}
    lg = LabeledPseudoColor{T1,o.alpha}
    return mappedarray(lg, img, labs)
end

function (o::OverlayLabels)(img::AbstractArray{T1}, labs::AbstractArray{T2}) where {T1<:AbstractPseudoColor,T2}
    la = reinterpret(reshape, ColoredLabel{T2,o.tab}, labs)
    lg = LabeledPseudoColor{T1,o.alpha}
    return mappedarray(lg, img, la)
end


_isbg_(c::ColoredLabel) = iszero(c.lab)
_isbg_(c::LabeledGray) = _isbg_(c.lab)
_isbg_(c::LabeledPseudoColor) = _isbg_(c.lab)
_blend_(col, c::LabeledGray{T,A}) where {T,A} = !_isbg_(c) ? A * col(c.lab) + (1 - A) * gray(c.val) : gray(c.val)
_blend_(col, c::LabeledPseudoColor{T,A}) where {T,A} = !_isbg_(c) ? A * col(c.lab) + (1 - A) * col(c.val) : col(c.val)