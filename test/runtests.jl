using ColorfulZz
using ColorTypes
using FixedPointNumbers
using Test

@testset "ColorfulZz.jl" begin
    lut = LUTS[:blue]
    @test ColorfulZz._tabred_(lut, 0f0) == 0
    @test ColorfulZz._tabgreen_(lut, 0f0) == 0
    @test ColorfulZz._tabblue_(lut, 0f0) == 0
    @test ColorfulZz._tabblue_(lut, 1f0) == 1
    @test blue(TabPseudoColor{Gray{N0f8}, lut}(Gray{N0f8}(1))) == 1
    fun = ColorFunction(r -> max(1 - 1.5 * r, 0), g -> 0.98 - 0.7 * g, b -> 0.88 - 0.5 * b^2)
    @test red(FunPseudoColor{N0f8, fun}(0)) == 1
end
