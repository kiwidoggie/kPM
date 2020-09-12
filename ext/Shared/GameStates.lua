GameStates =
{
    -- There is no gamestate, used for initialization
    None = 0,

    -- Warmup time, waiting for everyone to ready up
    Warmup = 1,

    -- After warmup, going into knife round transition
    WarmupToKnife = 2,

    -- Knife rounds
    KnifeRound = 3,

    -- After a winner has been selected via knife round transitition to first half
    KnifeToFirst = 4,

    -- Playing the first half
    FirstHalf = 5,

    -- Finished first half, switching to half time for the second rup period
    FirstToHalf = 6,

    -- Half-time in between halfs (rup again?)
    HalfTime = 7,

    -- Finished half time rup, switching to second
    HalfToSecond = 8,

    -- Second half of playtime
    SecondHalf = 9,

    -- Currently in a timeout
    Timeout = 10,

    -- Strat time before each round
    Strat = 11,

    -- Nade strat training
    NadeTraining = 12,

    -- End of a match
    EndGame = 13,

    Max = 14
}