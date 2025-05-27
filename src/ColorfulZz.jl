module ColorfulZz

using ColorTypes
using Colors: Colors, clamp01
using FixedPointNumbers
using MappedArrays
using Statistics # enlever juste pour quantile, mettre quantile rapide dans BaseZz

include("atype.jl")

export ScaledGray, ScaledPseudoColor, AutoMinMax, SetMinMax, AutoSaturateMinMax
include("scolors.jl")

export LUTS, ColorTable, TabPseudoColor, ColorFunction, FunPseudoColor, AsPseudoColor
include("pcolors.jl")
include("luts.jl")

export ColoredLabel, LabeledGray, LabeledPseudoColor, AsColoredLabeling, OverlayLabels
include("labeling.jl")

end
