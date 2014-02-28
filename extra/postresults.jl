Pkg.add("Requests")
Pkg.add("JSON")
using Requests
json_head = Dict{String, String}()
json_head["Content-Type"] = "application/json"

for file in readdir()
    if ismatch(r"json", file)
        json_str = readall(file)
        response = post(URI("http://127.0.0.1:8000/put/package"), json_str, json_head)
        println(response)
        println(response.data)
    end
end

Pkg.rm("Requests")
Pkg.rm("JSON")
