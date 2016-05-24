#-----------------------------------------------------------------------
# PackageEvaluator
# https://github.com/IainNZ/PackageEvaluator.jl
# (c) Iain Dunning 2015. MIT License.
#-----------------------------------------------------------------------
# website/pulse_plots.jl
# Makes the plots for the Pulse page:
# - The totals-by-version plot
# - The stars plot
# - The test status fraction plot
#-----------------------------------------------------------------------

print_with_color(:magenta, "Making plots for pulse page...\n")

using PyPlot
include("shared.jl")

# Load test history
star_db_file = ARGS[1]
hist_db_file = ARGS[2]
output_path  = ARGS[3]

# Load history databases
hist_db, pkgnames, dates = load_hist_db(hist_db_file)

print_with_color(:magenta, "  Totals and sanity checks...\n")

# Collect totals for each Julia version by date and status
totals = Dict()
for ver in ["0.2","0.3","0.4","0.5"]
    totals[ver] = Dict([date => Dict([status => 0 for status in keys(HUMANSTATUS)])
                        for date in dates])
    for pkg in pkgnames
        key = (pkg, ver)
        !(key in keys(hist_db)) && continue
        results = hist_db[key]
        for i in 1:size(results,1)
            date   = results[i,1]
            status = results[i,3]
            totals[ver][date][status]  += 1
            totals[ver][date]["total"] += 1
        end
    end
end

# Print some sanity check info, good for picking up massive failures
println("    ", dates[1], "  ", dates[2])
for status in keys(HUMANSTATUS)
    @printf("    %20s   %4d   %4d\n", status,
        totals["0.4"][dates[1]][status],
        totals["0.4"][dates[2]][status])
end

#-----------------------------------------------------------------------
# 1. MAIN PLOT
# Shows total packages by version
print_with_color(:magenta, "  Printing main plot...\n")

# Build an x-axis and y-axis for each version
x_dates  = Dict([ver=>Date[] for ver in keys(totals)])
y_totals = Dict([ver=>Int[]  for ver in keys(totals)])
for ver in keys(totals), date in dates
    y = totals[ver][date]["total"]
    y <= 0 && continue
    push!(x_dates[ver], dbdate_to_date(date))
    push!(y_totals[ver], y)
end
# Julia releases so far (release date, name, vertical height on plot, bold)
jl_date_vers = [Date(2014,08,20)  "v0.3.0"  250  true;
                Date(2014,09,21)  "v0.3.1"  300  false;
                Date(2014,10,21)  "v0.3.2"  250  false;
                Date(2014,11,23)  "v0.3.3"  300  false;
                Date(2014,12,26)  "v0.3.4"  250  false;
                Date(2015,01,08)  "v0.3.5"  300  false;
                Date(2015,02,17)  "v0.3.6"  250  false;
                Date(2015,03,23)  "v0.3.7"  300  false;
                Date(2015,04,30)  "v0.3.8"  250  false;
                Date(2015,05,30)  "v0.3.9"  300  false;
                Date(2015,06,24)  "v0.3.10" 250  false;
                Date(2015,07,27)  "v0.3.11" 300  false;
                Date(2015,10,26)  "v0.3.12" 250  false;
                Date(2015,10,08)  "v0.4.0"  400  true;
                Date(2015,11,08)  "v0.4.1"  450  false;
                Date(2015,12,06)  "v0.4.2"  400  false;
                Date(2016,01,12)  "v0.4.3"  450  false;
                Date(2016,03,17)  "v0.4.5"  400  false;
]
fig = figure(figsize=(10,4))  # inches
plot(x_dates["0.2"], y_totals["0.2"], "r-",
     x_dates["0.3"], y_totals["0.3"], "g-",
     x_dates["0.4"], y_totals["0.4"], "b-",
     x_dates["0.5"], y_totals["0.5"], "k-",
     linewidth=2)
for i in 1:size(jl_date_vers,1)
    annotate(xy=(jl_date_vers[i,1],jl_date_vers[i,3]), s=jl_date_vers[i,2],
             size="small", ha="center", backgroundcolor="w")
    axvline(x=jl_date_vers[i,1], alpha=1.0,
            color=jl_date_vers[i,4] ? "#333333" : "#cccccc")
end
xticks(rotation="vertical")
ylabel("Number of Tagged Packages")
legend(["0.2","0.3","0.4","0.5"], loc=2, fontsize="small")
open(joinpath(output_path,"allver.svg"), "w") do fp
    writemime(fp, "image/svg+xml", fig)
end


#-----------------------------------------------------------------------
# 2. STAR PLOT
# Shows total stars across time
print_with_color(:magenta, "  Printing star plot...\n")

star_hist, star_dates = load_star_db(star_db_file)
star_totals = [d => 0 for d in dates]
for pkg in keys(star_hist)
    for (date,stars) in star_hist[pkg]
        star_totals[date] += stars
    end
end

x_dates  = Date[]
y_totals = Int[]
for date in star_dates
    date == "20140925" && continue  # First entry, not accurate
    date == "20150620" && continue  # Weird spike, double counting?
    total = star_totals[date]
    if total > 10
        push!(x_dates, dbdate_to_date(date))
        push!(y_totals, total)
    end
end
fig = figure(figsize=(10,4))  # inches
plot(x_dates, y_totals,
     color="gold", marker="*",
     linestyle="solid", linewidth=2)
xticks(rotation="vertical")
ylabel("Number of stars")
open(joinpath(output_path,"stars.svg"), "w") do fp
    writemime(fp, "image/svg+xml", fig)
end


#-----------------------------------------------------------------------
# 3. VERSION PLOTS
print_with_color(:magenta, "  Printing version plots...\n")

const OLDCODES = ["full_pass","full_fail",
                  "using_pass","using_fail",
                  "not_possible","total"]
const NEWCODES = ["tests_pass","tests_fail",
                  "no_tests","not_possible","total"]

# Build an x-axis and y-axis for each version
jlv3 = Date(2014,08,20)
jlv4 = Date(2015,10,08)

for ver in keys(totals), aspercent in [true,false]
    x_dates_old  = Date[]
    y_totals_old = [key=>Any[] for key in OLDCODES]
    x_dates      = Date[]
    y_totals     = [key=>Any[] for key in NEWCODES]
    for i in 1:length(dates)
        v = totals[ver][dates[i]]
        d = dbdate_to_date(dates[i])
        if d <= Date(2015,6,18)
            # Old statuses
            if v["total"] > 0
                push!(x_dates_old, d)
                for key in OLDCODES
                    push!(y_totals_old[key],
                        aspercent ? v[key] / v["total"] * 100 :
                                    v[key])
                end
            end
        else
            # New statuses
            if v["total"] > 0
                push!(x_dates, d)
                for key in NEWCODES
                    push!(y_totals[key],
                        aspercent ? v[key] / v["total"] * 100 :
                                    v[key])
                end
            end
        end
    end
    fig = figure(figsize=(4,3))  # inches
    # OLDCODES
    plot(x_dates_old, y_totals_old["full_pass"],    color="green",  marker=".")
    plot(x_dates_old, y_totals_old["full_fail"],    color="orange", marker=".")
    plot(x_dates_old, y_totals_old["using_pass"],   color="blue",   marker=".")
    plot(x_dates_old, y_totals_old["using_fail"],   color="red",    marker=".")
    plot(x_dates_old, y_totals_old["not_possible"], color="grey",   marker=".")
    # NEWCODES
    plot(x_dates, y_totals["tests_pass"],   color="green",  marker=".")
    plot(x_dates, y_totals["tests_fail"],   color="red",    marker=".")
    plot(x_dates, y_totals["no_tests"],     color="blue",   marker=".")
    plot(x_dates, y_totals["not_possible"], color="grey",   marker=".")
    if ver == "0.3"
        annotate(xy=(jlv3,aspercent?35:550), s="v0.3",
                 size="small", ha="left", backgroundcolor="w")
        axvline(x=jlv3, alpha=1.0, color="#333333")
    end
    if ver == "0.3" || ver == "0.4"
        annotate(xy=(jlv4,aspercent?35:550), s="v0.4",
                 size="small", ha="left", backgroundcolor="w")
        axvline(x=jlv4, alpha=1.0, color="#333333")
    end
    xticks(rotation="vertical")
    ylabel(string(aspercent?"Percentage":"Number", " of Packages"))
    ylim(ymin = 0, ymax = aspercent ? 70 : 700 )
    title(string("Julia v$(ver)", aspercent ? " (relative)" : ""))
    open(joinpath(output_path,"$(ver)_$(aspercent).svg"), "w") do fp
        writemime(fp, "image/svg+xml", fig)
    end
end
