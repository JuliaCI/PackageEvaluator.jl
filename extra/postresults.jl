Pkg.add("Requests")
Pkg.add("JSON")
using Requests
json_head = Dict{String, String}()
json_head["Content-Type"] = "application/json"

for file in readdir()
    if ismatch(r"json", file)
        json_str = readall(file)
        #println(json_str)
        response = post(URI("http://status.julialang.org/put/package"), json_str, json_head)
        println(response)
        println(response.data)
    end
end
Pkg.rm("Requests")
Pkg.rm("JSON")
