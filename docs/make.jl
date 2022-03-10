using Tilde
using Documenter

DocMeta.setdocmeta!(Tilde, :DocTestSetup, :(using Tilde); recursive=true)

makedocs(;
    modules=[Tilde],
    authors="Chad Scherrer <chad.scherrer@gmail.com> and contributors",
    repo="https://github.com/cscherrer/Tilde.jl/blob/{commit}{path}#{line}",
    sitename="Tilde.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://cscherrer.github.io/Tilde.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/cscherrer/Tilde.jl",
    devbranch="main",
)
