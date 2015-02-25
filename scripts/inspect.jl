import JSON

for filename in ARGS
    j = JSON.parsefile(filename)

    print_with_color(:white, j["name"], "\n")
    j["status"] == "full_pass" && print_with_color(:green, j["status"])
    j["status"] == "full_fail" && print_with_color(:yellow, j["status"])
    j["status"] == "using_pass" && print_with_color(:blue, j["status"])
    j["status"] == "using_fail" && print_with_color(:red, j["status"])
    j["status"] == "not_possible" && print_with_color(:magenta, j["status"])
    println()

    action = chomp(readline())
    if action != ""
        println(j["log"])
    end
end