#import "@preview/min-manual:0.1.0": manual
#import "@preview/circuiteria:0.2.0"

#show: manual.with(
  title: "FDC-320 with Arduino",
  description: "How to operate the FDC-320 with Arduino controller",
  authors: "Torfi Þorgrímsson <mailto:torfit@gmail.com>",
  license: "Reykjavík University",
)

#show raw: set text(font: "iosevka")

= Quick Start
== Download git
Run `winget install Git.Git` in cmd or powershell on Windows

Run `sudo apt install git` on Linux

#heading(outlined: false)[make sure it's been included in the `PATH` environment variable]
Sometimes on windows `winget` won't put the git/julia executable in the path variable. It seems to always put it in the start menu so you can find the executable there and add it's path to the `PATH` environment variable.

== Download the github repository
```sh
git clone https://github.com/AwesomeQuest/fdc-320.git
```
The repo also has a copy of this manual in case you need another copy.
Feel free to open an issue or send me an email if you have any problems.

== Install Julia

#heading(outlined: false, level: 3)[Windows]
Run the following command in powershell or cmd
```sh
winget install JuliaLang.Julia
```

#heading(outlined: false, level: 3)[Linux]
Run the following command in your favorite shell
```sh
curl -fsSL https://install.julialang.org | sh
```


#pagebreak()
== Setup environment
Then open a Julia REPL in the `FDC-320` folder as follows
```
julia --project=.
```


And you should see something like this
```
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.12.0-rc1 (2025-07-12)
 _/ |\__'_|_|_|\__'_|  |  Official https://julialang.org release
|__/                   |

julia>
```

Install the required packages.

```jl
julia> ]

(fdc-320) pkg> instantiate
```

Then include the file `FDC320lib.jl`
```jl
julia> include("FDC320lib.jl")
```

== Querying the FDC-320
=== List available ports
Make sure the Arduino is plugged into your pc via USB. You check this with the following command.

```jl
julia> list_ports()
COM3
        Description:    Arduino Uno (COM3)
        Transport type: SP_TRANSPORT_USB
```
This command lists all the valid USB port names and their description. The example above is for a windows machine, on linux the name has a different format but is functionally equivalent.

=== Open the port
In order to use a USB port for serial communication you must "open" it first. This takes ownership of the port and makes sure no other processes can use it.

```jl
julia> port = LibSerialPort.open("COM3", 9600)

```
Here the first argument is the name of the port as shown by `list_ports()` and the second argument is the baud-rate. It is critical that the baud-rate be set the same as the Arduino, I have set it to 9600. The baud-rate of the FDC-320 is an internal setting and must be changed with the `setCommunicationBaudrate` function, then you must change the Arduino code to match.

=== Make a request
Now you can use the public API (Julia) to make requests to the FDC-320. Here is an example:
```jl
julia> get_ReadFlowrateActualFlowrate(port)
0.0f0
```

You can reference the FDC-300 manual pages 16-17 for the names of the available functions, each function either reads or writes to a register. In that table each register is marked either "Read only"(R), "Write only"(W), or "Read and write"(RW).

Each register gets one or two functions in the file `FDC320lib.jl` corresponding to if the register is R, W, or RW. If the register is marked R it gets a function of the same name prefixed with "get", if it is marked with W the function prefix is "set". If the register is RW then it gets both a "get" and a "set" function.

When calling a "set" function it is important to call it with the right type. This type is annotated in the table in the FDC-300 manual as `U16`, `U32`, or `Float`, these correspond to `UInt16`, `UInt32`, and `Float32` in Julia.

On a success the "set" function will return a `0`

Here are a few examples of dos and don'ts for a set function. (The function returning `0` means success)

```jl

julia> set_SetFlowrateActualFlowrate(port, 0.0f0)
0

julia> set_SetFlowrateActualFlowrate(port, 0.0e0)
ERROR: AssertionError: typeof(val) === regtypes[adr]
Stacktrace:
...

julia> set_SetFlowrateActualFlowrate(port, 0x01)
ERROR: AssertionError: typeof(val) === regtypes[adr]
Stacktrace:
...

julia> set_SetFlowrateActualFlowrate(port, Float32(0x01))
0


julia> set_SetFlowratePercentageMethod(port, 0x0001)
0

julia> set_SetFlowratePercentageMethod(port, 1)
ERROR: AssertionError: typeof(val) === regtypes[adr]
Stacktrace:
...

julia> set_SetFlowratePercentageMethod(port, 1.0)
ERROR: AssertionError: typeof(val) === regtypes[adr]
Stacktrace:
...

julia> set_SetFlowratePercentageMethod(port, UInt16(1.0))
0
```

As you can see, it is only valid to call the set function with that function's appropriate type as defined in the table.

= Logging data
In Julia it is most convenient to log data with the `CSV.jl` and `DataFrames.jl` packages. If you do not already have these installed you can do so as follows.

Go into Package mode by entering the `]` character. 
```jl
julia> ]

(fdc-320) pkg> add CSV, DataFrames
```

Then you include them in your namespace with a `using` statement.
```jl
julia> using CSV, DataFrames
```

The following is a simple example of logging and saving data

```jl
julia> using Dates

julia> times = []; datas = [];

julia> for _ in 1:100
           push!(datas, get_ReadFlowrateActualFlowrate(port))
           push!(times, now())
       end

julia> CSV.write("test.csv", DataFrame(timescolumn=times, datascolumn=datas))
"test.csv"

julia> CSV.read("test.csv", DataFrame)
100×2 DataFrame
 Row │ timescolumn              datascolumn 
     │ DateTime                 Float64     
─────┼──────────────────────────────────────
   1 │ 2025-08-07T12:16:43.107          0.0
   2 │ 2025-08-07T12:16:43.328          0.0
  ⋮ │            ⋮                    ⋮
  99 │ 2025-08-07T12:17:05.101          0.0
 100 │ 2025-08-07T12:17:05.316          0.0
                             96 rows omitted
```

#pagebreak()

= Reading Temperature and Humidity

The file `FDC320lib.jl` also contains a function to read the Temperature and Humidity detected by a DHT22. It is used as follows.

```jl
julia> T,H = TH = readTandH(port)
(temperature = 24.1f0, humidity = 48.100002f0)

julia> T
24.1f0

julia> H
48.100002f0

julia> (T,H) === (TH.temperature, TH.humidity)
true
```

The function returns a `NamedTuple` which can either indexed into like an array or via field like a struct.

= Arduino code and wiring
The Arduino is running the file `reader/reader.ino` and can be uploaded directly to the Arduino via the ArduinoIDE.

#figure(
  caption: [A wiring diagram of the Arduino, FDC, Multiplexer, and DHT22]
)[
#circuiteria.circuit({
import circuiteria: *

  element.block(
    x:4,y:0,w:4,h:10,
    id:"ard",
    name:"Arduino",
    fill: rgb("#008184"),
    ports: (
      east:(
        (id:"5V", name:"5V"),
        (id:"GND", name:"GND"),
        (id:"D5", name:"D5"),
        (id:"D3", name:"D3"),
        (id:"D2", name:"D2"),
      )
    )
  )
  
  element.block(
    x:10,y:3,w:4,h:6,
    id:"conv",
    name:"Multiplexer V3.0",
    fill: rgb("#737575"),
    ports: (
      west:(
        (id:"5V", name:"5V"),
        (id:"GND", name:"GND"),
        (id:"ARX", name:"A-RX"),
        (id:"ATX", name:"A-TX"),
      ),
      east:(
        (id:"BB", name:"B-B"),
        (id:"BA", name:"B-A"),
        (id:"5V2", name:"5V"),
        (id:"GND2", name:"GND"),

      )
    )
  )

  wire.wire("w", ("ard-port-5V", "conv-port-5V"),style:"zigzag")
  wire.wire("w", ("ard-port-GND", "conv-port-GND"),style:"zigzag")
  wire.wire("w", ("ard-port-D3", "conv-port-ATX"),style:"zigzag")
  wire.wire("w", ("ard-port-D5", "conv-port-ARX"),style:"zigzag")

  element.block(
    x:15,y:0,w:4,h:3,
    id:"dht",
    name:text("DHT22"),
    fill: rgb("#e3e4ec"),
    ports: (
      west:(
        (id:"5V", name:"5V"),
        (id:"GND", name:"GND"),
        (id:"DAT", name:"DAT"),
      )
    )
  )
  wire.wire("w", ("ard-port-D2", "dht-port-DAT"), style: "zigzag")
  wire.wire("w", ("conv-port-GND2", "dht-port-GND"), style: "zigzag")
  wire.wire("w", ("conv-port-5V2", "dht-port-5V"), style: "zigzag", zigzag-ratio: 70%)

  element.block(
    x:15,y:5,w:4,h:4,
    id:"fdc",
    name:"FDC-320",
    fill: rgb("#99a4fb"),
    ports: (
      west:(
        (id:"3", name:"3"),
        (id:"9", name:"9"),
      ),
      east:(
        (id:"2",name:"2"),
        (id:"7",name:"7"),
      )
    )
  )

  wire.wire("w", ("conv-port-BB", "fdc-port-3"), style: "zigzag")
  wire.wire("w", ("conv-port-BA", "fdc-port-9"), style: "zigzag")

  wire.stub("fdc-port-2", "east", name:"24V-VCC")
  wire.stub("fdc-port-7", "east", name:"VEE")

})
]

If you need to replace the multiplexer board it is called "Multi USB RS232 RS485 TTL Converter SKU TEL0070".


