extends Node

const rosewater = Color("f5e0dc")
const flamingo = Color("f2cdcd")
const pink = Color("f5c2e7")
const mauve = Color("cba6f7")
const red = Color("f38ba8")
const maroon = Color("eba0ac")
const peach = Color("fab387")
const yellow = Color("f9e2af")
const green = Color("a6e3a1")
const teal = Color("94e2d5")
const sky = Color("89dceb")
const sapphire = Color("74c7ec")
const blue = Color("87b0f9")
const lavender = Color("b4befe")
const text = Color("c6d0f5")
const subtext1 = Color("b3bcdf")
const subtext0 = Color("a1a8c9")
const overlay2 = Color("8e95b3")
const overlay1 = Color("7b819d")
const overlay0 = Color("696d86")
const surface2 = Color("565970")
const surface1 = Color("43465a")
const surface0 = Color("313244")
const base = Color("1e1e2e")
const mantle = Color("181825")
const crust = Color("11111b")

const pallette: Array = [mauve, sky, teal]
var pallette_head: int = 0

func palletteAvailable() -> bool:
	return not pallette.empty()

func getNextPalletteColour() -> Color:
	assert(palletteAvailable())
	
	var ret: Color = pallette[pallette_head]
	pallette_head = wrapi(pallette_head + 1, 0, len(pallette))
	return ret
