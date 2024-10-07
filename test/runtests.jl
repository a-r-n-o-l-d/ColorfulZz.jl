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

end
