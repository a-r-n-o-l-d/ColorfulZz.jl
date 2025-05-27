module ColorfulZz

using ColorTypes
using Colors: Colors, clamp01
using FixedPointNumbers
using MappedArrays
using Statistics # enlever juste pour quantile, mettre quantile rapide dans BaseZz

include("type.jl")

export ScaledGray, ScaledPseudoColor, AutoMinMax, SetMinMax, AutoSaturateMinMax
include("scaled-colors.jl")

export LUTS, ColorTable, TabPseudoColor, ColorFunction, FunPseudoColor, AsPseudoColor
include("pseudo-colors.jl")
include("luts.jl")

export ColoredLabel, LabeledGray, LabeledPseudoColor, AsColoredLabeling, OverlayLabels
include("labeling.jl")

end
