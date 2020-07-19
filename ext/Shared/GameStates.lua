GameStates =
{
    -- There is no gamestate, used for initialization
    None = 0,

    -- Warmup time, waiting for everyone to ready up
    Warmup = 1,

    -- Knife rounds
    KnifeRound = 2,

    -- Playing the first half
    FirstHalf = 3,

    -- Half-time in between halfs (rup again?)
    HalfTime = 4,

    -- Second half of playtime
    SecondHalf = 5,

    -- Currently in a timeout
    Timeout = 6,

    -- Strat time before each round
    Strat = 7,

    -- Nade strat training
    NadeTraining = 8,

    -- End of a match
    EndGame = 9
}