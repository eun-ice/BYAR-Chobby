
StringUtilities = StringUtilities or {}

function StringUtilities.GetTruncatedString(myString, myFont, maxLength)
    if (not maxLength) then
        return myString
    end
    if myFont:GetTextWidth(myString) <= maxLength then
        return myString
    end
    -- Binary search for the longest prefix that fits
    local lo, hi = 0, string.len(myString)
    local sub = string.sub
    while lo < hi do
        local mid = lo + math.floor((hi - lo + 1) / 2)
        if myFont:GetTextWidth(sub(myString, 1, mid)) <= maxLength then
            lo = mid
        else
            hi = mid - 1
        end
    end
    if lo < 1 then
        return ""
    end
    return sub(myString, 1, lo)
end

function StringUtilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local dotDotWidth = myFont:GetTextWidth("..")
	local truncation = StringUtilities.GetTruncatedString(myString, myFont, maxLength - dotDotWidth)
	return truncation .. ".."
end

function StringUtilities.TruncateStringIfRequired(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return StringUtilities.GetTruncatedString(myString, myFont, maxLength)
end

function StringUtilities.TruncateStringIfRequiredAndDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return StringUtilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
end

function StringUtilities.TruncateMiddle(value, threshold, headLength, tailLength)
	threshold = threshold or 20
	headLength = headLength or 8
	tailLength = tailLength or 8
	local s = tostring(value or "")
	if #s <= threshold then
		return s
	end
	return s:sub(1, headLength) .. "..." .. s:sub(-tailLength)
end

local function FuzzyScore(query, target)
	local queryLength = #query
	local targetLength = #target
	if queryLength == 0 or queryLength > targetLength then
		return 0
	end

	local score = 0
	local queryIndex = 1
	local consecutive = 0
	local lastMatchPosition = 0

	for targetIndex = 1, targetLength do
		if queryIndex <= queryLength and string.byte(target, targetIndex) == string.byte(query, queryIndex) then
			if lastMatchPosition > 0 then
				local gap = targetIndex - lastMatchPosition - 1
				if gap > 0 then
					score = score - gap
					consecutive = 0
				end
			end

			score = score + 1
			consecutive = consecutive + 1
			if consecutive > 1 then
				score = score + consecutive
			end

			if targetIndex > 1 then
				local previous = string.byte(target, targetIndex - 1)
				if previous == 32 or previous == 95 or previous == 45 then
					score = score + 4
				end
			elseif targetIndex == 1 then
				score = score + 5
			end

			score = score + math.max(0, (20 - targetIndex) * 0.1)
			lastMatchPosition = targetIndex
			queryIndex = queryIndex + 1
		elseif queryIndex <= queryLength then
			consecutive = 0
		end
	end

	if queryIndex <= queryLength then
		return 0
	end
	return score + math.max(0, 3 - (targetLength - queryLength) * 0.1)
end

function StringUtilities.MatchesSearchQuery(query, searchableValues, gameName)
	if not query or query == "" then
		return true
	end

	local lowerQuery = string.lower(query)
	local queryWithoutSpaces = lowerQuery:gsub("%s+", "")
	local lowerValues = {}
	for _, value in pairs(searchableValues) do
		if value then
			lowerValues[#lowerValues + 1] = string.lower(value)
		end
	end

	local lowerGameName
	if #queryWithoutSpaces >= 5 and gameName then
		lowerGameName = string.lower(gameName)
		lowerValues[#lowerValues + 1] = lowerGameName
	end

	local matched = false
	if lowerGameName then
		if string.find(lowerGameName, queryWithoutSpaces, 1, true) then
			matched = true
		elseif #queryWithoutSpaces == 40 and string.find(queryWithoutSpaces, "^[0-9a-f]+$") then
			local shortHash8 = string.sub(queryWithoutSpaces, 1, 8)
			local shortHash7 = string.sub(queryWithoutSpaces, 1, 7)
			if string.find(lowerGameName, shortHash8, 1, true) or string.find(lowerGameName, shortHash7, 1, true) then
				matched = true
			end
		end
	end

	local queryWords = {}
	for word in lowerQuery:gmatch("%S+") do
		queryWords[#queryWords + 1] = word
	end

	if not matched and #queryWords <= 1 then
		for _, value in ipairs(lowerValues) do
			if string.find(value, lowerQuery, 1, true) then
				matched = true
				break
			end
		end
	else
		local combinedValues = table.concat(lowerValues, " ")
		local allFound = true
		for _, word in ipairs(queryWords) do
			if not string.find(combinedValues, word, 1, true) then
				allFound = false
				break
			end
		end
		if allFound then
			matched = true
		end
	end

	if not matched and #queryWithoutSpaces >= 4 then
		local threshold = #queryWithoutSpaces * 3
		for _, value in ipairs(lowerValues) do
			if FuzzyScore(queryWithoutSpaces, value) >= threshold then
				matched = true
				break
			end
		end
	end

	return matched
end

function string.starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
	return End=='' or string.sub(String,-string.len(End))==End
end

function string.trim(str)
	return str:match'^()%s*$' and '' or str:match'^%s*(.*%S)'
end
