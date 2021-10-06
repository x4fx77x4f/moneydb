--@name calculateHand test
--@server
--@include casino/poker/sh_cards.lua
--@include casino/poker/sh_payout.lua
local function printf(...)
	return print(string.format(...))
end

local testsPassed, testsTotal = 0, 0
local function test(desc, cond)
	testsPassed = testsPassed+(cond and 1 or 0)
	testsTotal = testsTotal+1
	printf("#%d: %s: %s", testsTotal, cond and "PASS" or "FAIL", desc)
end
local function testString(desc, a, b)
	local cond = a == b
	testsPassed = testsPassed+(cond and 1 or 0)
	testsTotal = testsTotal+1
	printf("#%d: %s: %s", testsTotal, cond and "PASS" or "FAIL", desc)
	if not cond then
		printf("\texpected %q, got %q", tostring(a), tostring(b))
	end
end

dofile('casino/poker/sh_cards.lua')
dofile('casino/poker/sh_payout.lua')
local function generateHand(...)
	local hand = {...}
	for k, v in pairs(hand) do
		hand[k] = cards[v]
	end
	return hand
end

testString("Royal flush", "Royal flush", calculateHand(generateHand(1, 13, 12, 11, 10)))
testString("Royal flush", "Royal flush", calculateHand(generateHand(14, 26, 25, 24, 23)))
testString("Royal flush", "Royal flush", calculateHand(generateHand(27, 39, 38, 37, 36)))
testString("Royal flush", "Royal flush", calculateHand(generateHand(40, 52, 51, 50, 49)))
testString("Straight flush", "Straight flush", calculateHand(generateHand(1, 2, 3, 4, 5)))
test("Straight flush", "Straight flush" ~= calculateHand(generateHand(11, 12, 13, 14, 15)))
testString("Flush", "Flush", calculateHand(generateHand(52, 49, 46, 45, 43)))
testString("Four of a kind", "Four of a kind", calculateHand(generateHand(9, 22, 35, 48, 1)))
testString("Three of a kind", "Three of a kind", calculateHand(generateHand(9, 22, 35, 2, 1)))
testString("Full house", "Full house", calculateHand(generateHand(1, 14, 27, 2, 15)))
testString("Straight", "Straight", calculateHand(generateHand(1, 2, 16, 17, 31)))
testString("Straight", "Straight", calculateHand(generateHand(1, 13, 25, 37, 49)))
testString("Two pair", "Two pair", calculateHand(generateHand(11, 50, 43, 30, 9)))
testString("One pair", "One pair", calculateHand(generateHand(4, 30, 39, 23, 44)))

printf("\n%s: Passed %d of %d tests (%d%%)", testsPassed == testsTotal and "PASS" or "FAIL", testsPassed, testsTotal, math.ceil(testsPassed/testsTotal*100-0.5))
