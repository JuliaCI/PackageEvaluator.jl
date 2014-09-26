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
