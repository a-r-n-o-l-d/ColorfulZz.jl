using ColorfulZz
using Documenter

DocMeta.setdocmeta!(ColorfulZz, :DocTestSetup, :(using ColorfulZz); recursive=true)

makedocs(;
    modules=[ColorfulZz],
    authors="Arnold",
    sitename="ColorfulZz.jl",
    format=Documenter.HTML(;
        canonical="https://a-r-n-o-l-d.github.io/ColorfulZz.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/a-r-n-o-l-d/ColorfulZz.jl",
    devbranch="main",
)
