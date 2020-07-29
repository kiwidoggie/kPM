/*
    I hate javascript with a burning passion
    I'm pretty sure that web developers are masochistic
    like someone come get they mans.

    kPM.js
    Library for managing the WebUI of kPM mod
*/

/**
 * List of Page ID's.
 * 
 * These must match Shared/GameStates.lua
 */
const GameStates =
{
    None: 0,
    Warmup: 1,
    KnifeRound: 2,
    FirstHalf: 3,
    HalfTime: 4,
    SecondHalf: 5,
    Timeout: 6,
    Strat: 7,
    NadeTraining: 8,
    EndGame: 9
}

function IsElementValid(p_Element)
{
    return p_Element != null && p_Element != undefined;
}

function ChangeState(p_GameState)
{
    // Validate that our index is within the bounds
    if (p_GameState < GameStates.None || p_GameState > GameStates.EndGame)
    {
        console.error("invalid gamestate index.");
        return false;
    }

    // Get all of the div's by ID

    // Get the warmup page
    var s_WarmupPage = document.getElementById("page_warmup");
    if (!IsElementValid(s_WarmupPage))
    {
        console.error("could not get the warmup page.");
        return false;
    }

    // Get the knife round page
    var s_KnifePage = document.getElementById("page_knife");
    if (!IsElementValid(s_KnifePage))
    {
        console.error("could not get knife page.");
        return false;
    }

    // Get the first round page
    var s_FirstRoundPage = document.getElementById("page_firsthalf");
    if (!IsElementValid(s_FirstRoundPage))
    {
        console.error("could not get first half round paage.");
        return false;
    }

    
}