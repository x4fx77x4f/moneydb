# MoneyDB casino collection
A collection of scripts useful for running StarfallEx-based casinos. Includes MoneyDB, which allows for the management of money on servers that do not have their own money system.

## Warning
The gambling machines in this repository do not use cryptographically secure random number generation, and are intended for entertainment purposes only. Don't use fake money you particularly care about, and definitely don't use any form of real money or anything that can be exchanged for real money. There are only a limited number of extremely basic sanity and security checks, and they should not be depended upon.

Additionally, the backend code is not well written and the API is not well designed, and there are known bugs that may cause crashes, corruption of the MoneyDB database, or crazy values. Machines should be monitored and babysat to ensure everything is working fine, since they tend to act up sometimes.

## Usage (user)
1. `git clone https://github.com/x4fx77x4f/moneydb.git`
2. `ln -s "$(realpath moneydb)" ~/.steam/steam/steamapps/common/GarrysMod/garrysmod/data/starfall/casino`
3. Flash `casino/moneydb/init.lua` to a chip
4. Flash `casino/atm/init.lua` to another chip and connect a screen to it (recommended but not required)
5. Flash any MoneyDB compatible code to another chip (such as `casino/poker/init.lua`)

## Usage (developer)
I have included sample code here. Additionally, see [`moneydb/init_demo.lua`](moneydb/init_demo.lua), the MoneyDB source code, as well as the source code of the ATM and poker machine.
```lua
--@server
--@include casino/moneydb/sv_lib.lua
require('casino/moneydb/sv_lib.lua')
assert(moneydb.init(), "could not find host")
moneydb.getBalance(owner(), function(success, balance)
	print(string.format("Your balance: $%d", balance))
end)
```
The balance is a signed integer that has a bit width that is implementation defined, and stored in `MDB_MONEY_WIDTH`. It is important that you always use that constant rather than just assuming that it will stay the same, as corruption can occur if the wrong width is used. Constants are defined in [`moneydb/sh_constants.lua`](moneydb/sh_constants.lua).

## API
***Entity or nil*** host `= moneydb.init(`***Player or nil*** owner of host`)`

Looks for and finds any MoneyDB host chips owned by the provided owner, or the owner of the current chip if not specified. If a host is found, `moneydb.host` is set to it and it is returned. Otherwise, `nil` is returned.

***void*** `moneydb.onInit(`***function*** callback, ***Player or nil*** owner of host`)`

Similar to `moneydb.init`, but asynchronous. The callback will be called with a single parameter of `true` once a host is found. If no host is found, it will keep trying indefinitely.

***void*** `moneydb.increaseBalance(`***Player or string*** entity or SteamID, ***number*** amount, ***function*** callback`)`

Increases the player's balance by a certain amount. The callback will be called with a single boolean parameter that is either `true` or `false` depending on whether the operation succeeded.

***void*** `moneydb.decreaseBalance(`***Player or string*** entity or SteamID, ***number*** amount, ***function*** callback`)`

Decreases the player's balance by a certain amount. The callback will be called with a single boolean parameter that is either `true` or `false` depending on whether the operation succeeded.

***void*** `moneydb.transferMoney(`***Player or string*** source, ***Player or string*** destination, ***number*** amount, ***function*** callback`)`

Decreases the source player's balance by a certain amount, and increase's the destination player's balance by the same amount. The callback will be called with a single boolean parameter that is either `true` or `false` depending on whether the operation succeeded.

***void*** `moneydb.getBalance(`***Player or string*** entity or SteamID, ***function*** callback`)`

Gets the player's balance. The callback will be called with a boolean parameter that is either `true` or `false` depending on whether the operation succeeded, and a number parameter corresponding to the player's balance.

***void*** `moneydb.setBalance(`***Player or string*** entity or SteamID, ***number*** amount, ***function*** callback`)`

Sets the player's balance. The callback will be called with a single boolean parameter that is either `true` or `false` depending on whether the operation succeeded.

***number*** index `= moneydb.addToQueue(`***function*** callback, ***number*** action, ***varargs*** parameters`)`

**For internal use only.** Manually injects an action into the queue. You should not use numbers directly as they are implementation defined, instead you should use the constants starting with `MDB_ACTION_`. Needed parameters vary depending on the action.
