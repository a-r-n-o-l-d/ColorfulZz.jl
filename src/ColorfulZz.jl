module ColorfulZz

using ColorTypes
using Colors: Colors, clamp01
using FixedPointNumbers
using MappedArrays
using Statistics # enlever juste pour quantile, mettre quantile rapide dans BaseZz

include("atype.jl")

export LUTS, ColorTable, TabPseudoColor, ColorFunction, FunPseudoColor, AsPseudoColor
include("luts.jl")
include("pcolors.jl")

export ScaledGray, ScaledPseudoColor, AutoMinMax, SetMinMax, AutoSaturateMinMax
include("scolors.jl")

export ColoredLabel
include("labeling.jl")

end
