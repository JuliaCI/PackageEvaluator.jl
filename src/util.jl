# run_cap_all
# A wrapper around spawn that captures STDOUT and STDERR and sticks them in
# a file of the users choosing, and returns that combined stream.
function run_cap_all(cmd, log_file)
    out_fp = open(log_file,"w")
    proc = nothing
    proc = spawn(cmd, Base.DevNull, out_fp, out_fp)
    while process_running(proc)
        sleep(0.5)
    end
    close(out_fp)
    return readall(log_file), proc.exitcode == 0
end


# build_log
# Take the three log components, truncate them if needed, and then mash
# them together to get a nice log
function build_log(pkg_name, add_log, using_log, full_log)
    function trunc_section(s)
        l = split(s,"\n")
        if length(l) >= 75
            return join(vcat(l[1:20],{"... truncated ..."},l[end-50:end]),"\n")
        end
        return s
    end
    log_str  = ">>> 'Pkg.add(\"$(pkg_name)\")' log\n"
    log_str *= trunc_section(add_log)
    log_str *= "\n>>> 'using $(pkg_name)' log\n"
    log_str *= trunc_section(using_log)
    log_str *= "\n>>> test log\n"
    log_str *= trunc_section(full_log)
    log_str *= "\n>>> end of log"
    return log_str
end


# featuresToJSON
# Takes test results and formats them as a JSON string
function featuresToJSON(pkg_name, features, jsonpath)
    output_dict = {
        "jlver"             => string(VERSION.major,".",VERSION.minor),
        "name"              => pkg_name,
        "url"               => features[:URL],
        "version"           => features[:VERSION],
        "gitsha"            => chomp(features[:GITSHA]),
        "gitdate"           => chomp(features[:GITDATE]),
        "license"           => features[:LICENSE],
        "licfile"           => features[:LICENSE_FILE],
        "status"            => features[:TEST_STATUS],
        "expnames"          => get(features,:EXP_NAMES,{}),
        "log"               => build_log(pkg_name,  features[:ADD_LOG],
                                                    features[:TEST_USING_LOG],
                                                    features[:TEST_FULL_LOG]),
        "possible"          => features[:TEST_POSSIBLE] ? "true" : "false",
        "testfile"          => features[:TEST_MASTERFILE]
    }
    j_path = joinpath(jsonpath,pkg_name*".json")
    print_with_color(:yellow, "PKGEVAL: Creating JSON file $j_path\n")
    fp = open(j_path,"w")
    JSON.print(fp, output_dict)
    close(fp)
end
