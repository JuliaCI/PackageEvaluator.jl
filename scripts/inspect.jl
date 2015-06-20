import JSON

for filename in ARGS
    j = JSON.parsefile(filename)

    print_with_color(:white, j["name"], "\n")
    j["status"] == "tests_pass" && print_with_color(:green, j["status"])
    j["status"] == "tests_fail" && print_with_color(:red, j["status"])
    j["status"] == "no_tests" && print_with_color(:blue, j["status"])
    j["status"] == "not_possible" && print_with_color(:magenta, j["status"])
    println()

    action = chomp(readline())
    if action != ""
        println(j["log"])
    end
end