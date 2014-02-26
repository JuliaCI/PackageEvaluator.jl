Pkg.add("GitHub")
using GitHub

auth = authenticate(readall("token.txt"))


packages_to_open_on = ["JuMP"]