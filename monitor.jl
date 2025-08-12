using GLMakie, Dates

include("FDC320lib.jl")
port = LibSerialPort.open("COM3", 9600)

fig = Figure()
ax = Axis(fig[1,1])

actflow = Observable(0f0)
prcflow = Observable(0x0000)
warning = Observable(0x0000)

timearr = Observable([Time(now())])
actflowarr = Observable([0.0])
prcflowarr = Observable([0.0])
lines!(ax, timearr, actflowarr)
lines!(ax, timearr, prcflowarr)

setactflow = Observable(0f0)
setprcflow = Observable(0x0000)

Label(fig[0,1], text=@lift("""
Actual Flowrate: $($actflow)
Percentage Flowrate: $(1e-3*$prcflow)

Set Actual Flowrate: $($setactflow)
Set Percentage Flowrate: $($setprcflow)

Warning: $($warning)
"""); tellwidth=false, fontsize=30)

stop = 0
errormonitor(@async while stop == 0
	actflow[] = get_ReadFlowrateActualFlowrate(port)
	prcflow[] = get_ReadFlowratePercentageMethod(port)
	warning[] = get_WarningCode(port)

	setactflow[] = get_SetFlowrateActualFlowrate(port)
	setprcflow[] = get_SetFlowratePercentageMethod(port)

	push!(actflowarr[], 1.0actflow[])
	push!(prcflowarr[], 1e-3prcflow[])
	push!(timearr[], now())
	notify(actflowarr)
	notify(prcflowarr)
	notify(timearr)
	reset_limits!(ax)
	sleep(1)
end)

fig