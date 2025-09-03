using LibSerialPort, GLMakie, Dates
using Instruments


rm = ResourceManager()
instruments = find_resources(rm) # returns a list of VISA strings for all found instruments
uwSource = GenericInstrument()
Instruments.connect!(rm, uwSource, "GPIB0::24::INSTR")
@info query(uwSource, "*IDN?") # prints "Rohde&Schwarz,SMIQ...."


write(uwSource, "*RST")
write(uwSource, "SOUR:FUNC VOLT")
write(uwSource, "SENS:FUNC 'CURR'")
write(uwSource, "FORM:DATA REAL,32")
write(uwSource, "FORM:BORD SWAP")
write(uwSource, "OUTP ON")

voltage = 0.1
maxcurrent = 1
maxresistance = 0.1
write(uwSource, "SENS:CURR:PROT $(min(voltage/maxresistance, maxcurrent))")

write(uwSource, "SOUR:VOLT $voltage")

# ard = LibSerialPort.open("COM3", 115200)
serialmonitor = Channel(Inf)
currdate = now()

# errormonitor(@async try

@warn "I don't know why this has to be here"

errormonitor(Threads.@spawn begin
while isopen(ard)
	since = now()
	# write(ard, 0x0a)
	# temphumi = readuntil(ard, 0x0a)
	# length(temphumi) == 8 || (@show String(temphumi); continue)
	voltage,current = nothing, nothing
	try
		voltage,current = reinterpret(Float32, query(uwSource, "MEAS:CURR?"; delay=0.01)[3:end] |> codeunits)
	catch
		continue
	end
	# temp,humi = temphumi |> x->reinterpret(Float32, x)
	# put!(serialmonitor, (since,temp,humi,current,voltage))
	put!(serialmonitor, (since,current,voltage))
	sleep(0.01)
end
end)

# @warn 1

# since, humi, temp, crnt = take!(serialmonitor)
since, crnt = take!(serialmonitor)

# global temps = Observable(Point2[(since,temp)])
# global humis = Observable(Point2[(since,humi)])
global crnts = Observable(Point2[(since,crnt)])

# since, humi, temp, crnt = take!(serialmonitor)
since, crnt = take!(serialmonitor)
# push!(humis[], (since, humi))
# push!(temps[], (since, temp))
push!(crnts[], (since, crnt))
# @warn 1

global fig = Figure(size=(900,400))
ax1 = Axis(fig[1,1:2], yticklabelcolor = :red, yaxisposition = :right)
ax2 = Axis(fig[1,1:2], yticklabelcolor = :blue, yaxisposition = :left)
hidespines!(ax2)
hidexdecorations!(ax2)

# currtemp = @lift round(last(last($temps)), digits=1)
# currhumi = @lift round(last(last($humis)), digits=1)
currcrnt = @lift round(last(last($crnts)), digits=1)
# @warn 1

# Label(fig[0,1],
# 	@lift("The Temperature is $($currtemp) °C"),
# 	tellheight=true, tellwidth=false,
# 	color = :red,
# 	fontsize = 30
# )
# Label(fig[0,2],
# 	@lift("The Humidity is $($currhumi) %"),
# 	tellheight=true, tellwidth=false,
# 	color = :blue,
# 	fontsize = 30
# )
# @warn 1

# on(Button(fig[2,1], label="Reset Y-Axis limits", tellwidth=false).clicks) do n
# 	since = time() - now
# 	lasttimetemps = findfirst(x->x[1]>since, temps[])
# 	lasttimetemps === nothing && (lasttimetemps = 1)
# 	Tmin,Tmax = extrema(x->x[2], @view temps[][lasttimetemps:end])
# 	Hmin,Hmax = extrema(x->x[2], @view humis[][lasttimetemps:end])
# 	ylims!(ax1, Tmin-0.1,Tmax+0.1)
# 	ylims!(ax2, Hmin-0.1,Hmax+0.1)
# 	display(fig)
# end


lines!(ax1, @lift($crnts .|> x->x[1].instant.periods.value), @lift($crnts .|> x->x[2]), color=:red)
# lines!(ax2, @lift($humis .|> x->x[1].instant.periods.value), @lift($humis .|> x->x[2]), color=:blue)

ax1.ylabel = "Current [A]"
ax2.ylabel = "Humidity [%]"

ax1.xlabel = "Time since January 1st 1970 [ms]"
# @warn 1

display(fig)

errormonitor(begin
@async for i in serialmonitor
	since, humi, temp, crnt = i
	since, crnt = i
	# humi = clamp(humi, 0,100)
	# push!(humis[], (since, humi))
	# push!(temps[], (since, temp))
	push!(crnts[], (since, crnt))
	# notify(humis)
	# notify(temps)
	notify(crnts)

	xlims!(ax1,since.instant.periods.value-100_000, since.instant.periods.value)
	xlims!(ax2,since.instant.periods.value-100_000, since.instant.periods.value)
	
	display(fig)
	yield()
end
end
)
# @warn 1

@info "here"
while isopen(fig.scene)
	sleep(0.1)
end


# finally
# close(ard)
# close(serialmonitor)
# end)