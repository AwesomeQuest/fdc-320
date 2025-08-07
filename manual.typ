#import "@preview/min-manual:0.1.0": manual

#show: manual.with(
  title: "Package Name",
  description: "How to opperate the FDC-320 with Arduino controller",
  authors: "Torfi Þorgrímsson <mailto:torfit@gmail.com>",
  license: "MIT",
)

#show raw: set text(font: "iosevka")

= Quick Start
== Download the github repo
First clone the github repo
```sh
git clone https://github.com/AwesomeQuest/fdc-320.git
```

Feel free to open an issue or send me an email if you have any problems.

== Install Julia
Second you must install the Julia language

=== Windows
Run the following command in powershell or cmd
```sh
winget install JuliaLang.Julia
```

=== Linux
Run the following command in your favorite shell
```sh
curl -fsSL https://install.julialang.org | sh
```

== Setup environment
Then open a Julia REPL in the `FDC-320` folder
```
julia --project=.
```

#pagebreak()

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

Then include the file `FDC320lib.jl`
```jl
julia> include("FDC320lib.jl")
```

This file automatically puts the relevant libraries in your namespace.

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
SerialPort(Ptr{LibSerialPort.Lib.SPPort}(0x00000243cd500590), false, true, 0x00000000, 0x00000000)
```
Here the first argument is the name of the port as shown by `list_ports()` and the second argument is the baud-rate. It is critical that the baud-rate be set the same as the Arduino, I have set it to 9600. The baud-rate of the FDC-320 is an internal setting and must be changed with the `setCommunicationAddress` function, then you must change the Arduino code to match.

