const regtypes = Dict(
	0x01 => UInt16,
	0x10 => Float32,
	0x16 => UInt16,
	0x20 => Float32,
	0x26 => UInt16,

	0x30 => UInt16,
	0x31 => UInt16,
	0x32 => UInt16,
	
	0x2a => UInt16,
	0x2d => UInt16,
	0x41 => UInt16,
	0x51 => UInt32,
	0x53 => UInt16,
	0x61 => UInt16,
	0x80 => UInt8,
	0x87 => Float32,
)


function crc16(buff)::UInt16
	table_crc_hi = (
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
		0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
		0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
		0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
		0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
		0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40,
		0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1,
		0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
		0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
		0x80, 0x41, 0x00, 0xC1, 0x81, 0x40
	)
	table_crc_lo = (
		0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06,
		0x07, 0xC7, 0x05, 0xC5, 0xC4, 0x04, 0xCC, 0x0C, 0x0D, 0xCD,
		0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09,
		0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A,
		0x1E, 0xDE, 0xDF, 0x1F, 0xDD, 0x1D, 0x1C, 0xDC, 0x14, 0xD4,
		0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
		0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3,
		0xF2, 0x32, 0x36, 0xF6, 0xF7, 0x37, 0xF5, 0x35, 0x34, 0xF4,
		0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A,
		0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29,
		0xEB, 0x2B, 0x2A, 0xEA, 0xEE, 0x2E, 0x2F, 0xEF, 0x2D, 0xED,
		0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
		0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60,
		0x61, 0xA1, 0x63, 0xA3, 0xA2, 0x62, 0x66, 0xA6, 0xA7, 0x67,
		0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F,
		0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68,
		0x78, 0xB8, 0xB9, 0x79, 0xBB, 0x7B, 0x7A, 0xBA, 0xBE, 0x7E,
		0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
		0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71,
		0x70, 0xB0, 0x50, 0x90, 0x91, 0x51, 0x93, 0x53, 0x52, 0x92,
		0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C,
		0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B,
		0x99, 0x59, 0x58, 0x98, 0x88, 0x48, 0x49, 0x89, 0x4B, 0x8B,
		0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
		0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42,
		0x43, 0x83, 0x41, 0x81, 0x80, 0x40
	)

	crc_hi = 0xff
	crc_lo = 0xff
	i::UInt32 = 0

	buffer_length = length(buff)
	buffind = 1

	while buffer_length > 0
		buffer_length -= 1
		i = crc_hi ⊻ buff[buffind]
		buffind += 1

		crc_hi = crc_lo ⊻ table_crc_hi[i+1]
		crc_lo = table_crc_lo[i+1]
	end

	UInt16(crc_hi) << 8 | crc_lo
end

function readuntilpause(port, pause = 0.1)
	buff = UInt8[]

	lastmsg = time()
	while isopen(port) && time()-lastmsg < 100e-3
		curr = read(port)
		isempty(curr) && continue
		append!(buff, curr)
		lastmsg = time()
	end

	buff
end

function readRegisters(port, id::Unsigned, adr::Unsigned)
	tmp = UInt8['\n', id, adr]
	crc = crc16(tmp)
	tmp = [tmp; UInt8(crc >> 8); UInt8(crc & 0xff)]

	write(port, tmp)

	buff = UInt8[]

	IDMISS = b"ID CRC MISMATCH"
	WRONGREG = b"INCORRECT REGISTER"
	SERTIME = b"SERIAL TIMEOUT"
	MODFAIL = b"FAIL"
	GOODEND = b"SUCCESS\r\n"
	T = time()
	while isopen(port) && time()-T < 2.0
		append!(buff, read(port))
		@debug buff

		if !isnothing(findfirst(GOODEND, buff))
			append!(buff, readuntilpause(port, 0.1))
					
			msgstart = last(findfirst(GOODEND, buff)) + 1
			msgend = first(findnext(b"\r\n", buff, msgstart)) - 1

			msg = buff[msgstart:msgend]

			appcrc = reinterpret(UInt16,msg[end-1:end])[1] |> bswap
			clccrc = crc16(msg[1:end-2])

			appcrc !== clccrc && error("CRC MISMATCH\n The CRC of the returned message does not match the actual CRC \n $(string(clccrc, base=16)) != $(string(appcrc, base=16)) \n msg = $msg")

			return msg[4:4+msg[3]-1]
		end
		
		if !isnothing(findfirst(IDMISS, buff)) || !isnothing(findfirst(WRONGREG, buff)) || !isnothing(findfirst(SERTIME, buff))
			append!(buff, readuntilpause(port, 0.1))
			error("The arduino returned an error:\n$(buff)")
		end

		if !isnothing(findfirst(MODFAIL, buff))
			append!(buff, readuntilpause(port, 0.1))

			errormsg = "The modbus returned an error: "
			errline = findfirst(b"The error code is: ", buff)
			errlineend = findnext(b"\n", buff, last(errline))
			errnum = @view buff[last(errline)+1:errlineend[1]-1]
			errormsg *= String(errnum)

			errnum = parse(UInt8, String(errnum))
			if errnum === 0x81
				errormsg *= """
				Sensor abnormality/valve leakage
				Troubleshooting:
				In the non-ventilated state, zero adjustment is completed after preheating
				"""
			elseif errnum === 0x82
				errormsg *= """
					Abnormal airsource
					Troubleshooting:
					Check air source"""
				
			elseif errnum === 0x83
				errormsg *= """
					Abnomal power supply voltage
					Troubleshooting:
					Check supply voltage"""
				
			elseif errnum === 0x84
				errormsg *= """
					Set signal over the limit
					Troubleshooting:
					Check the set signal value"""
				
			else
				errormsg *= """
					Unkown error
					Troubleshooting:
					If the problem still cannot be solved according to the above process, you need to contact the manufacturer's technical personnel to investigate and solve the problem."""
			end

			error(errormsg)
		end
	end

	!isopen(port) && error("Port closed\n Current buffer:\n$(buff)")
	error("Timeout error, arduino took too long or didn't send the right stuff\n Current buffer:\n$(buff)")

end

function writeRegisters(port, id::UInt8, adr::UInt8, val)
	@assert typeof(val) === regtypes[adr]
	tmp1 = UInt8['\r', id, adr]
	crc1 = crc16(tmp1)
	tmp1 = [tmp1; UInt8(crc1 >> 8); UInt8(crc1 & 0xff)]

	
	tmp2 = reinterpret(UInt8, [val])
	tmp2 = typeof(val) === Float32 ? tmp2[[2,1,4,3]] : reverse(tmp2)
	crc2 = crc16(tmp2)
	tmp2 = [tmp2; UInt8(crc2 >> 8); UInt8(crc2 & 0xff)]

	write(port, [tmp1;tmp2])

	buff = UInt8[]

	IDMISS = b"ID CRC MISMATCH"
	WRONGREG = b"INCORRECT REGISTER"
	SERTIME = b"SERIAL TIMEOUT"
	DATAMISS = b"DATA CRC MISMATCH"
	MODFAIL = b"FAIL"
	GOODEND = b"SUCCESS"
	T = time()
	while isopen(port) && time()-T < 2.0
		append!(buff, read(port))
		@debug buff
		!isnothing(findfirst(GOODEND, buff)) && return 0
		
		if !isnothing(findfirst(IDMISS, buff)) || !isnothing(findfirst(WRONGREG, buff)) || !isnothing(findfirst(SERTIME, buff)) || !isnothing(findfirst(DATAMISS, buff))
			append!(buff, readuntilpause(port, 0.1))
			error("The arduino returned an error:\n$(buff)")
		end
		
		if !isnothing(findfirst(MODFAIL, buff))
			append!(buff, readuntilpause(port, 0.1))

			errormsg = "The modbus returned an error: "
			errline = findfirst(b"The error code is: ", buff)
			errlineend = findnext(b"\n", buff, last(errline))
			errnum = @view buff[last(errline)+1:errlineend[1]-1]
			errormsg *= String(errnum)

			errnum = parse(UInt8, String(errnum))
			if errnum === 0x81
				errormsg *= """
				Sensor abnormality/valve leakage
				Troubleshooting:
				In the non-ventilated state, zero adjustment is completed after preheating
				"""
			elseif errnum === 0x82
				errormsg *= """
					Abnormal airsource
					Troubleshooting:
					Check air source"""
				
			elseif errnum === 0x83
				errormsg *= """
					Abnomal power supply voltage
					Troubleshooting:
					Check supply voltage"""
				
			elseif errnum === 0x84
				errormsg *= """
					Set signal over the limit
					Troubleshooting:
					Check the set signal value"""
				
			else
				errormsg *= """
					Unkown error
					Troubleshooting:
					If the problem still cannot be solved according to the above process, you need to contact the manufacturer's technical personnel to investigate and solve the problem."""
			end

			error(errormsg)
		end
	end

	!isopen(port) && error("Port closed\n Current buffer:\n$(buff)")
	error("Timeout error, arduino took too long or didn't send the right stuff\n Current buffer:\n$(buff)")
end

"""
If data 0x0101 is returned, the communication test is successful.
"""
function get_CommunicationTest(port; id=0x01)
	adr = 0x01
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
The unit defaults to SCCM, and floating point numbers are encoded according to IEEE 754, with the low byte first and the high byte last.
"""
function get_ReadFlowrateActualFlowrate(port; id=0x01)
	adr = 0x10
	reinterpret(regtypes[adr], readRegisters(port, id, adr)[[3,4,1,2]])[1] |> bswap
end

"""
0-10000=0-100.00% * full scale.
"""
function get_ReadFlowratePercentageMethod(port; id=0x01)
	adr = 0x16
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
The flow unit defaults to SCCM, and floating point numbers are encoded by IEEE 754, with the low digit first and the high digit last. (You can only choose one of the two traffic setting methods)
"""
function get_SetFlowrateActualFlowrate(port; id=0x01)
	adr = 0x20
	reinterpret(regtypes[adr], readRegisters(port, id, adr)[[3,4,1,2]])[1] |> bswap
end

"""
The flow unit defaults to SCCM, and floating point numbers are encoded by IEEE 754, with the low digit first and the high digit last. (You can only choose one of the two traffic setting methods)
"""
function set_SetFlowrateActualFlowrate(port, val; id=0x01)
	adr = 0x20
	writeRegisters(port, id, adr, val)
end

"""
0-10000=0-100.00% * full scale
(You can only choose one of the two traffic setting methods)
"""
function get_SetFlowratePercentageMethod(port; id=0x01)
	adr = 0x26
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
0-10000=0-100.00% * full scale
(You can only choose one of the two traffic setting methods)
"""
function set_SetFlowratePercentageMethod(port, val; id=0x01)
	adr = 0x26
	writeRegisters(port, id, adr, val)
end

"""
Address range 1-99.
"""
function get_CommunicationAddress(port; id=0x01)
	adr = 0x30
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
Address range 1-99.
"""
function set_CommunicationAddress(port, val; id=0x01)
	adr = 0x30
	writeRegisters(port, id, adr, val)
end

"""
Baud rate = sent value * 100; such as 96, corresponding baud rate is 9600 Bps.
"""
function get_CommunicationbBaudrate(port; id=0x01)
	adr = 0x31
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
Baud rate = sent value * 100; such as 96, corresponding baud rate is 9600 Bps.
"""
function set_CommunicationBaudrate(port, val; id=0x01)
	adr = 0x31
	writeRegisters(port, id, adr, val)
end

"""
0: No parity; 1: Odd parity; 2: Even parity.
"""
function get_CommunicationCheckbit(port; id=0x01)
	adr = 0x32
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
0: No parity; 1: Odd parity; 2: Even parity.
"""
function set_CommunicationCheckbit(port, val; id=0x01)
	adr = 0x32
	writeRegisters(port, id, adr, val)
end

"""
0: Normal control; 2: Cleaning (open at full power)
If the cleaning function is not required, there is no need to perform this operation, and the default is the normal control state.
"""
function get_ValveControl(port; id=0x01)
	adr = 0x2a
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
0: Normal control; 2: Cleaning (open at full power)
If the cleaning function is not required, there is no need to perform this operation, and the default is the normal control state.
"""
function set_ValveControl(port, val; id=0x01)
	adr = 0x2a
	writeRegisters(port, id, adr, val)
end

"""
1: Rs485 communication; 2: Analog communication.
"""
function get_CommunicationMethod(port; id=0x01)
	adr = 0x2d
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
1: Rs485 communication; 2: Analog communication.
"""
function set_CommunicationMethod(port, val; id=0x01)
	adr = 0x2d
	writeRegisters(port, id, adr, val)
end

"""
Send 0xf0 to perform an auto-zero (make sure no gas is passing through to do this).
"""
function set_EquipmentZeroing(port; id=0x01)
	adr = 0x41
	writeRegisters(port, id, adr, val)
end

"""
The unit defaults to smL, with low bits in front and high bits in the back.
"""
function get_AccumulatedFlowrate(port; id=0x01)
	adr = 0x51
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
Send data: 0x01, then perform clearing.
"""
function set_AccumulationCleared(port; id=0x01)
	adr = 0x53
	writeRegisters(port, id, adr, val)
end

"""
See Appendix 1 for the warning code table for details.
"""
function get_WarningCode(port; id=0x01)
	adr = 0x61
	reinterpret(regtypes[adr], readRegisters(port, id, adr))[1] |> bswap
end

"""
Corresponds to the ASCII code table.
"""
function get_CalibrationGas(port; id=0x01)
	adr = 0x80
	String(readRegisters(port, id, adr))
end

"""
The unit defaults to SCCM, and floating point numbers are encoded according to IEEE 754, with the low bit first and the high bit last.
"""
function get_CalibratedRange(port; id=0x01)
	adr = 0x87
	reinterpret(regtypes[adr], readRegisters(port, id, adr)[[3,4,1,2]])[1] |> bswap
end

function readTandH(port)
	write(port, 0x0c)
	ret = readuntilpause(port)

	clccrc = crc16(@view ret[1:end-2])
	appcrc = reinterpret(UInt16, ret[end-1:end])[1]
	appcrc !== clccrc && error("CRC MISMATCH\nThe CRC of the returned message does not match the actual CRC \n 0x$(string(clccrc, base=16)) != 0x$(string(appcrc, base=16)) \n msg = $buff")

	T, H = reinterpret(Float32, ret[4:4+7])

	(temperature=T, humidity=H)
end

function setmultiplexer(port, control::Unsigned)
	crc = crc16([0x0b, UInt8(control & 0xff)])
	write(port, [0x0b, control, UInt8(crc >> 8); UInt8(crc & 0xff)])

	ret = readuntilpause(port)

	return ret
end

function setmultiplexer(port, d1::Bool,d2::Bool,d3::Bool,d4::Bool, input::Bool)
	control = (d1) | (d2 << 1) | (d3 << 2) | (d4 << 3) | (input << 4)
	return setmultiplexer(port, control)
end

function setmultiplexer(control::Signed)
	control = UInt8(Unsigned(control) & 0xff | 0b10000)
	return setmultiplexer(port, control)
end

using LibSerialPort
