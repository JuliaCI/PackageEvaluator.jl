#######################################################################
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015
# Licensed under the MIT License
#######################################################################
# Assembles a JSON containing the add logs and test logs, if they
# exist, as well as other useful information about the package.
#######################################################################

include("constants.jl")
include("JSON.jl/src/JSON.jl")

function check_license(filename)
    text = lowercase(readall(filename))
    for license in LICENSES
        for regex in license[2]
            if ismatch(regex, text)
                return true, license[1]
            end
        end
    end
    return false, "Unknown"
end


function prepare_json()
    pkg_name = ARGS[1]
    exit_code = ARGS[2]
    json_path = ARGS[3]

    url_path = joinpath(Pkg.dir(),"METADATA",pkg_name,"url")
    url      = chomp(readall(url_path))
    url      = (url[1:3] == "git")   ? url[7:(end-4)] :
               (url[1:5] == "https") ? url[9:(end-4)] : ""
    url      = string("http://", url)

    old_dir = pwd()
    cd(Pkg.dir(pkg_name))
    # gitlog = "08ab40...c96c40 2014-05-22 17:17:40 -0400"
    gitlog   = readall(`git log -1 --format="%H %ci"`)
    spl      = split(gitlog, " ")
    git_sha  = spl[1]
    git_date = string(spl[2]," ",spl[3]," ",spl[4])
    cd(old_dir)

    lic_file, license = "", "Unkown"
    for lic_file in LICFILES
        fullfilename = joinpath(Pkg.dir(pkg_name), lic_file)
        if isfile(fullfilename)
            is_license, license = check_license(fullfilename)
            is_license && break
        end
    end

    add_log = readall("PKGEVAL_$(pkg_name)_add.log")

    if exit_code == "255"
        # No tests were run because they couldn't be
        test_log = "Package was unable to be tested."
        test_status = "not_possible"
    elseif exit_code == "254"
        # No tests could be found
        test_log = "No tests found."
        test_status = "no_tests"
    elseif exit_code == "0"
        # Tests ran and passed
        test_log = readall("PKGEVAL_$(pkg_name)_add.log")
        test_status = "tests_pass"
    elseif exit_code == "1" || exit_code == "124"
        # Test ran and failed or timed out
        test_log = readall("PKGEVAL_$(pkg_name)_add.log")
        test_status = "tests_fail"
    end

    log_str  = ">>> 'Pkg.add(\"$(pkg_name)\")' log\n"
    log_str *= add_log
    log_str *= "\n>>> 'Pkg.test(\"$(pkg_name)\")' log\n"
    log_str *= test_log
    log_str *= "\n>>> End of log"

    output_dict = {
        "jlver"             => string(VERSION.major,".",VERSION.minor),
        "name"              => pkg_name,
        "url"               => url,
        "version"           => string(Pkg.installed(pkg_name)),
        "gitsha"            => chomp(git_sha),
        "gitdate"           => chomp(git_date),
        "license"           => license,
        "licfile"           => lic_file,
        "status"            => test_status,
        "exit_code"         => exit_code,
        "log"               => log_str
    }
    fp = open(joinpath(json_path,pkg_name*".json"),"w")
    JSON.print(fp, output_dict)
    close(fp)
end

prepare_json()