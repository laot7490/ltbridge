--- Get largest distance, internal.
--- @param options any
--- @return number
--- @ltbridge internal
function GetLargestDistance(options)
    local largestDistance = -1
    for _, v in pairs(options) do
        if v.distance and v.distance > largestDistance then
            largestDistance = v.distance
        end
    end
    return largestDistance ~= -1 and largestDistance or 2.0
end