class 'TableHelper'

function TableHelper:contains(table, val)
    for i = 1, #table do
        if table[i] == val then
            return true
        end
    end
    return false
end

function TableHelper:empty(table)
    for _, _ in pairs(table) do
        return false
    end
    return true
end

return TableHelper
