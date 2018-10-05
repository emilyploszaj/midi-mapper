# midi-mapper
midi-mapper is a windows program that binds midi inputs, or combinations of inputs, to a keyboard key. It also comes with a built in web client for viewing midi activity in the form of a standard 5 octave piano keyboard. Despite not being shown on this display, any method of midi input should work with key bindings.

## Compiling/Installation
You can clone and build midi-mapper using dub, the standard package manager for D. This requires a D compiler, I suggest dmd.

## Settings
The config.json file is used to control all of the settings and bindings of the program, an example is included in the repository that binds a C major chord (C4, E4, G4) to the W key. Here's a list of the settings and what they do:
* **log-midi** if the program should output the raw midi input in the format "status data1 data2".
* **run-webserver** if the program should run a vibe.d webserver that can be connected to in order to view all midi activity.
* **port** the port the webserver should run on. This does nothing if you've set **run-webserver** to false.
* **input-id** the internal midi id the program should bind to. If you're not sure just start at 0 and work up, it should be one of the first ones.
* **inputs** the list of bindings the program should use in the following json object:
	* **keycode** the windows keycode value to be used in base 10. A list of hexadecimal virtual key codes can be found [here](https://docs.microsoft.com/en-us/windows/desktop/inputdev/virtual-key-codes).
	* **midi** is a list of midi numbers that form your "chord". **keycode** will only be pressed once every element in **midi** is pressed at once. A list of midi values can be found [here](https://newt.phys.unsw.edu.au/jw/notes.html).