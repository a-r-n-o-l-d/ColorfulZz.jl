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
