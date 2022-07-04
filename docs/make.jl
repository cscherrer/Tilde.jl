using Tilde
using Documenter

import Literate

include(joinpath(dirname(dirname(@__FILE__)), "test", "examples-list.jl"))

pages_before_examples = ["Home" => "index.md", "Installing Tilde" => "installing-Tilde.md"]
pages_examples =
    ["Examples" => ["$(example[1])" => "example-$(example[2]).md" for example in EXAMPLES]]
pages_after_examples = [
    "Tilde API" => "api.md",
    "TildeMLJ.jl" => "Tildemlj.md",
    "Internals" => "internals.md",
    "Miscellaneous" => "misc.md",
    "To-Do List" => "to-do-list.md",
]
pages = vcat(pages_before_examples, pages_examples, pages_after_examples)

# Use Literate.jl to generate Markdown files for each of the examples
for example in EXAMPLES
    input_file = joinpath(EXAMPLESROOT, "example-$(example[2]).jl")
    Literate.markdown(input_file, DOCSOURCE)
end

DocMeta.setdocmeta!(Tilde, :DocTestSetup, quote
    using Tilde
    import Random
    Random.seed!(3)
end; recursive = true)

makedocs(;
    modules = [Tilde],
    format = Documenter.HTML(),
    pages = pages,
    repo = "https://github.com/cscherrer/Tilde.jl/blob/{commit}{path}#L{line}",
    sitename = "Tilde.jl",
    authors = "Chad Scherrer",
    strict = true,
)

deploydocs(; repo = "github.com/cscherrer/Tilde.jl", push_preview = true)
