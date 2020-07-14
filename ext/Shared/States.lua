kPMStates =
{
    -- There is no gamestate, used for initialization
    None = 0,

    -- Warmup time, waiting for everyone to ready up
    Warmup = 1,

    -- Playing the first half
    FirstHalf = 2,

    -- Half-time in between halfs (rup again?)
    HalfTime = 3,

    -- Second half of playtime
    SecondHalf = 4,

    -- Currently in a timeout
    Timeout = 5,

    -- Nade strat training
    Strat = 6,

    -- End of a match
    EndGame = 7
}