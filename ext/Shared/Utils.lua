Utils =
{
    _Ignored = 1,

    starts_with = function(p_InputString, p_StartsWith)
        return p_InputString:sub(1, #p_StartsWith) == p_StartsWith
    end,

    ends_with = function(p_InputString, p_EndsWith)
        return p_EndsWith == "" or p_InputString:sub(-#p_EndsWith) == p_EndsWith
    end,

    contains = function(p_InputString, p_Contains)
        return string.find(p_InputString, p_Contains) ~= nil
    end,
}