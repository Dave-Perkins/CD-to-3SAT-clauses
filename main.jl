#!/usr/bin/env julia

"""
Simple runner script that can be called from the project root.
This makes it easy to run the project from anywhere.
"""

# Change to the scripts directory and run main.jl
cd(joinpath(@__DIR__, "scripts"))
include("main.jl")
