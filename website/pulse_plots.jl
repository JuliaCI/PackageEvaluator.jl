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

using Gadfly
include("shared.jl")

# Load test history
star_db_file = ARGS[1]
hist_db_file = ARGS[2]
output_path  = ARGS[3]

# Load history databases
hist_db, pkgnames, dates = load_hist_db(hist_db_file)

# Collect totals for each Julia version by date and status
totals = Dict()
for ver in ["0.2","0.3","0.4"]
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
println(dates[1], "  ", dates[2])
for status in keys(HUMANSTATUS)
    print(status, "  ")
    print(totals["0.4"][dates[1]][status])
    print("  ")
    print(totals["0.4"][dates[2]][status])
    println()
end

#-----------------------------------------------------------------------
# 1. MAIN PLOT
# Shows total packages by version
println("Printing main plot...")

# Build an x-axis and y-axis for each version
x_dates  = Dict([ver=>Date[] for ver in keys(totals)])
y_totals = Dict([ver=>Int[]  for ver in keys(totals)])
for ver in keys(totals)
    for date in dates
        y = totals[ver][date]["total"]
        if y > 0
            push!(x_dates[ver], dbdate_to_date(date))
            push!(y_totals[ver], y)
        end
    end
end
# Julia releases so far
jl_date_vers = [Date(2014,08,20)  "v0.3.0→"  100;
                Date(2014,09,21)  "v0.3.1→"  100;
                Date(2014,10,21)  "v0.3.2→"  100;
                Date(2014,11,23)  "v0.3.3→"  100;
                Date(2014,12,26)  "v0.3.4→"  100;
                Date(2015,01,08)  ""        100;
                Date(2015,02,17)  "v0.3.6→"  100;
                Date(2015,03,23)  "v0.3.7→"  100;
                Date(2015,04,30)  "v0.3.8→"  100;
                Date(2015,05,30)  "v0.3.9→"  100;
                Date(2015,05,30)  "v0.3.9→"  100;
                Date(2015,06,24)  ""        100;
                Date(2015,07,27)  "v0.3.11→" 100;
                Date(2015,10,08)  "v0.4.0→"  200]
p = plot(
    layer(x=x_dates["0.2"],y=y_totals["0.2"],color=fill("0.2",length(x_dates["0.2"])),Geom.line),
    layer(x=x_dates["0.3"],y=y_totals["0.3"],color=fill("0.3",length(x_dates["0.3"])),Geom.line),
    layer(x=x_dates["0.4"],y=y_totals["0.4"],color=fill("0.4",length(x_dates["0.4"])),Geom.line),
    # Julia release lines
    layer(x=map(d->(d+Dates.Day(4)), jl_date_vers[:,1]),  # Correct offset
          y=jl_date_vers[:,3],
          label=jl_date_vers[:,2],
          Geom.label(position=:left)),
    layer(xintercept=jl_date_vers[:,1],
          Geom.vline(color=colorant"gray50", size=1px)),
    # Axis labels
    Scale.y_continuous(minvalue=250,maxvalue=700),
    Guide.ylabel("Number of Tagged Packages"),
    Guide.xlabel("Date"),
    Guide.colorkey("Julia ver."),
    Theme(line_width=3px,label_placement_iterations=0))
draw(SVG(joinpath(output_path,"allver.svg"), 10inch, 4inch), p)

#-----------------------------------------------------------------------
# 2. STAR PLOT
# Shows total stars across time
println("Printing star plot...")

star_hist, star_dates = load_star_db(star_db_file)
star_totals = [d => 0 for d in dates]
for pkg in keys(star_hist)
    for (date,stars) in star_hist[pkg]
        star_totals[date] += stars
    end
end

x_dates  = Date[]
y_totals = Int[]
for (date,total) in star_totals
    date == "20140925" && continue  # First entry, not accurate
    date == "20150620" && continue  # Weird spike, double counting?
    if total > 10
        push!(x_dates, dbdate_to_date(date))
        push!(y_totals, total)
    end
end
p = plot(
    layer(x=x_dates,y=y_totals,color=ones(length(y_totals)),Geom.line),
    Scale.color_discrete_manual(colorant"gold"),
    Guide.ylabel("Number of Stars"),
    Guide.xlabel("Date"),
    Theme(line_width=3px,key_position=:none))
draw(SVG(joinpath(output_path,"stars.svg"), 8inch, 3inch), p)


#-----------------------------------------------------------------------
# 3. VERSION PLOTS
const OLDCODES = ["full_pass","full_fail",
                  "using_pass","using_fail",
                  "not_possible","total"]
const NEWCODES = ["tests_pass","tests_fail",
                  "no_tests","not_possible","total"]

# Build an x-axis and y-axis for each version
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
    p = plot(
        [layer(x=x_dates_old,
               y=y_totals_old[key],
               color=fill("old"*key,length(x_dates_old)),
               Geom.line) 
            for key in OLDCODES[1:end-1]]...,
        [layer(x=x_dates,
               y=y_totals[key],
               color=fill("new"*key,length(x_dates)),
               Geom.line) 
            for key in NEWCODES[1:end-1]]...,
        Scale.y_continuous(
            minvalue=0,
            maxvalue=aspercent?100:450),
        Guide.ylabel(string(aspercent?"Percentage":"Number",
                            " of Packages"), orientation=:vertical),
        Guide.xlabel("Date"),
        Guide.title(string("Julia v$(ver)", aspercent ? " (relative)" : "")),
        Scale.color_discrete_manual("green","orange","blue","red","grey",
                                    "green","red","blue","grey"),
        Theme(key_position=:none))
    draw(SVG(joinpath(output_path,"$(ver)_$(aspercent).svg"), 4inch, 3inch), p)
end