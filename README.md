# Wincraft

Poorly named, Wincraft is software to control the state of wires in MC and create windows to manipulate those states without requiring any programmation knowledge. 

![alt text](./doc/welcome.png "Welcome Screen")

## Features:
* multi-users and multi-screens with synchronized data
* advanced control and automation features
* replaces programming by intuitive screens
* data is saved automatically

## Architecture:
* one server that controls and reports the state of the wires
* one or more clients displaying data and allowing users to interact with the server
* transparently uses lan or wi-fi

## Requires:
* Opencomputers 1.7.10 up to 1.12.2
* Project Red or such wires

## Basics of signal:
* The server is connected to [redstone block(s)](https://ocdoc.cil.li/block:redstone_io) via special [cables](https://ocdoc.cil.li/block:cable) 
* Signal cables are connected to sides of that (those) redstone block(s)
* Each cable contains 16 different colored wires
* The server individually reports and modifies the state of those colored wires

# Standard wincraft screens:

## Generic screen:
It's aim is to display and allow changing the state of wires (0 (off) - 255 (on)).
The user chooses a redstone block and a side after which the window displays the state of the 16 wires concerned and allows the user to switch their state.

![alt text](./doc/generic/genericScreen.png "Generic Screen")

## Aliases screen:
This window aims to create, modify and set the state of aliases. An alias is a node or a leaf of a tree item (think directory).
A node can contain nodes and leaves while a leaf references a specific wire.

### Aliases have 2 roles:
* more readable than a triplet of redstone block/side/wire (just like an URL is more readable than an IP address)
* allows regrouping wires so one command can change all of them
* also, aliases are executed on the server in a different thread

![alt text](./doc/alias/aliasScreen.png "Aliases Screen")

### Content:
* output... forget about that, will probably disappear in the future
* IsDoor: allows to make sure doors are opened or closed (different rules than the rest)
* triplet of redstone block/side/wire
* buttons to to turn the alias on or off. Displays the state of a leaf. A node will effect all the leaves contained

## Orders screen:
Orders contain order commands. Executing an order will create a thread on the server and then execute the order commands in their respective order. An order can be killed. Repeat will repeat all the commands the specified amount of times.

![alt text](./doc/orders/ordersScreen.png "Orders Screen")

### Type of order commands:
* output: sets the state (0-255) of a triplet (redstone block/side/wire)
* outputAlias: sets the state (0-255) of an alias and all it's leaves if it's a node
* wait: sets an amount of seconds to wait
* input: waits for the state of the specified wire to be >= of the specified state
* execOrder: executes the specified order
* killOrder: ends the specified order
* cleanOut: clean commands are executed at the end of ther list of commands and if/when a command is killed.
* cleanOAl: same as cleanoput but uses an alias
* cleanW: same as wait but executed at the end or when an order is killed

### Type of order commands linked to variables:
They will make more sense after reading the doc on the variables window
* varSet: sets a variable. A number can be set, incremented and decremented by a value. Strings, booleans, alias and order types can be set depending on their type. 
* execVAl: equivalent to outputAlias but to the alias the specified variables equals to
* execVOr: equivalent to execOrder but to the order the specified variables equals to
* inpVar: equivalent to input but listens for a change of value for the specified variable
* trigVar: triggers any inpVar listening for the specified variable

## Orders List screen:
Lists all recorded orders, displays their state (running or not) and allows starting and killing them. NB, they end by themselves when they executed all their commands.

![alt text](./doc/orders/OrdersList.png "Orders List Screen")

## Variables screen:
Variables can be created and their value set from this window. They are organized in a tree.

![alt text](./doc/variables/variablesScreen.png "Variables Screen")

### Type of variables:
* number
* string
* boolean
* alias
* order

### Content of the window:
* name
* node or not
* type
* save: data change from this window is always saved but not forcefully from other sources. This tells the program if the variable value needs to be saved on hard drive when it is saved from other sources (orders and custom windows).
* value. What value can be contained will depend on the type

Caution: variables can make the program crash if pointing towards aliases or orders that don't exist anymore. I need to protect against that but haven't yet.

## ApplicationFactory screen
This window permits the creation of custom applications that can be found under the Custom menu. Those are created for the computer on which they were created and not synchronized/saved elsewhere. It's a vertical list of controls.
First, you give it a name, then a vertical size and distance between vertical elements.
Then, you add the controls you want to see appear. 

![alt text](./doc/appliFactory/appliFactory.png "AppliFactory Screen")

### Control options:
* output: a title, a triplet (redstone block/side/wire) and a charge when on (off is 0) - allows controlling it
* outAlias: same for an alias
* execOrder: order to control
* display: a title, a triplet (redstone block/side/wire) and a charge when on (off is 0) - only displays the info
* nothing: adds a vertical space
* variable: displays the value of a variable
* updVar: displays and allow modifying the value of a variable

You can also change the colors if you wish:

![alt text](./doc/appliFactory/palette.png "Palette Screen")

This will result in, for example:

![alt text](./doc/appliFactory/appliBase.png "AppliBase Screen")

You can create as many of such as you wish.

NB1: custom windows won't react properly if you have 2 controls dealing with the same wire and only one wire
NB2: it's is easy to crash the application by creating custom applications that use an order, alias or variable that you then rename or delete.

# Installation

## Hardware
You will need at minimum a server and one client to run wincraft.
Either have the server and it's clients on a lan or equip them all with a wifi network card. Mixing can work too.
You can locate all the computers inside a server rack if you want or not. 
NB on a previous version of Opencomputers, there was a bug where wifi cards wouldn't be able to communicate between computers inside a rack so if you use that solution, make sure to get the last version of the mod.

## Software:
* from the https://github.com/schloops1/wincraft page (this one) click "clone or download" then click "download zip".
* extract all the files (the content of wincraft-master) into the home directory of your Opencomputer's server and client(s) hard drives
* delete the doc directories if you need space
* if you are running on a 1.7.10 version of minecraft, you need to set the variable higherThan_1_7_10 (contained in the settings.json file of the server) to false.
* modify the .shrc file (should have extracted directly into home or you chose the wrong spot) of your server and client(s). Server .shrc should contain "srv" (no quotes) and client "client" (no quotes). That way, the computers will launch wincraft at boot.

# Warning:
This is for private networks. It is not suited for public networks where you can't trust all users as it certainly could be abused to crash the server. It is possible to crash the client but no data loss should occur so you can simply restart it. The server can be crashed with variable shenanigans but equally, no data loss should occur. I'll add additional security to counter that.
Anyway, it should be perfectly useable as it currently is.
* srv -enter or client-enter to launch the programs manually

If you want some errors to display on the screen of the client, modify client.lua so that "local safe = true" becomes "local safe = false" .
Client and server have a setting.json file where you can set a debug variable to true if you wish for loging to be written to log.txt. 
They also contain the variable port.
