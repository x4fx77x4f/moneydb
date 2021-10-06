--@shared
payouts = {
	[0] = {"Nothing", 0}, -- clientside only
	{"Royal flush", 100},
	{"Straight flush", 50},
	{"Four of a kind", 10},
	{"Full house", 5},
	{"Flush", 4},
	{"Straight", 3},
	{"Three of a kind", 2},
	{"Two pair", 1.5},
	{"One pair", 1.25}
}
payoutsLookup = {}
for i, pair in pairs(payouts) do
	payoutsLookup[pair[1]] = {i, pair[2]}
end
payoutWidth = 8
local royalFlush = { -- A, K, Q, J, 10 in any suit
	{[ 1]=1, [13]=1, [12]=1, [11]=1, [10]=1},
	{[14]=1, [26]=1, [25]=1, [24]=1, [23]=1},
	{[27]=1, [39]=1, [38]=1, [37]=1, [36]=1},
	{[40]=1, [52]=1, [51]=1, [50]=1, [49]=1}
}
function calculateHand(hand)
	-- Full house
	local uniqueRanks = {}
	for _, card in pairs(hand) do
		local rank = card.rank
		uniqueRanks[rank] = (uniqueRanks[rank] or 0)+1
	end
	local threes, twos
	for rank, num in pairs(uniqueRanks) do
		if num == 3 then
			threes = true
			if twos then
				return "Full house"
			end
		elseif num == 2 then
			twos = true
			if threes then
				return "Full house"
			end
		end
	end
	-- Flush
	local suit = hand[1].suit
	local flush = true
	for i=2, 5 do
		if hand[i].suit ~= suit then
			flush = false
			break
		end
	end
	-- Royal flush
	if flush then
		local uniqueCards = {}
		for i, card in pairs(hand) do
			local ci = card.index
			uniqueCards[ci] = (uniqueCards[ci] or 0)+1
		end
		for _, winningHand in pairs(royalFlush) do
			local winner = true
			for i, count in pairs(winningHand) do
				if uniqueCards[i] ~= count then
					winner = false
					break
				end
			end
			if winner then
				return "Royal flush"
			end
		end
	end
	-- Straight flush / Straight
	local sortedHand = {hand[1].rank, hand[2].rank, hand[3].rank, hand[4].rank, hand[5].rank}
	table.sort(sortedHand)
	local lastCard = sortedHand[1]
	local straight = true
	for i=2, 5 do
		local thisCard = sortedHand[i]
		if thisCard ~= lastCard+1 and not (lastCard == 1 and thisCard == 10) then
			straight = false
			break
		end
		lastCard = thisCard
	end
	if flush then
		return straight and "Straight flush" or "Flush"
	end
	-- * of a kind / * pair
	local nPair = 0
	for rank, num in pairs(uniqueRanks) do
		if num == 4 then
			return "Four of a kind"
		elseif num == 3 then
			return straight and "Straight" or "Three of a kind"
		elseif num == 2 then
			nPair = nPair+1
		end
	end
	if straight then
		return "Straight"
	elseif nPair == 2 then
		return "Two pair"
	elseif nPair == 1 then
		return "One pair"
	end
end
