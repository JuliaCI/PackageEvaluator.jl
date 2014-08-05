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