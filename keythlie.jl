using Dates
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

function readvolandcurr(uwSource)
	voltage,current = reinterpret(Float32, query(uwSource, "MEAS:CURR?"; delay=0.01)[3:end] |> codeunits)
	(V = voltage, C = current)
end