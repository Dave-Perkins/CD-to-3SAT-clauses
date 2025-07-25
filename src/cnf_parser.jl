"""
CNF file parsing functionality.
Translates DIMACS CNF format to Julia data structures.
"""

"""
    parse_cnf_file(filename::String) -> (num_vars::Int, num_clauses::Int, clauses::Vector{Vector{Int}})

Parse a DIMACS CNF file and return the number of variables, number of clauses, and the clauses themselves.
"""
function parse_cnf_file(filename::String)
    clauses = Vector{Vector{Int}}()
    num_vars = 0
    num_clauses = 0
    
    open(filename, "r") do file
        for line in eachline(file)
            line = strip(line)
            if startswith(line, "c") || startswith(line, "%")  # comment or end-of-file marker
                continue
            elseif startswith(line, "p cnf")  # problem line
                parts = split(line)
                num_vars = parse(Int, parts[3])
                num_clauses = parse(Int, parts[4])
            elseif !isempty(line) && !startswith(line, "c") && !startswith(line, "%")  # clause line
                clause_parts = split(line)
                clause = [parse(Int, x) for x in clause_parts if x != "0"]  # remove trailing 0
                if !isempty(clause)
                    push!(clauses, clause)
                end
            end
        end
    end
    
    return num_vars, num_clauses, clauses
end

"""
    analyze_cnf_structure(clauses::Vector{Vector{Int}}) -> Dict

Analyze the structural properties of a CNF formula.
"""
function analyze_cnf_structure(clauses::Vector{Vector{Int}})
    clause_lengths = [length(clause) for clause in clauses]
    variables_used = Set{Int}()
    
    for clause in clauses
        for literal in clause
            push!(variables_used, abs(literal))
        end
    end
    
    return Dict(
        :clause_count => length(clauses),
        :clause_lengths => clause_lengths,
        :unique_clause_lengths => unique(clause_lengths),
        :variables_used => sort(collect(variables_used)),
        :num_variables => length(variables_used)
    )
end
