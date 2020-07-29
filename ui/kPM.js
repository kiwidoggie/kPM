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

/**
 * Page names.
 * 
 * These must match the GameStates enumerration
 */
const GameStatesPages =
{
    None: "_invalid_id",
    Warmup: "page_warmup",
    KnifeRound: "page_kniferound",
    FirstHalf: "page_firsthalf",
    HalfTime: "page_halftime",
    SecondHalf: "page_secondhalf",
    Timeout: "page_timeout",
    Start: "page_strat",
    NadeTraining: "page_nadetraining",
    EndGame: "page_endgame"
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
    var s_FirstHalfPage = document.getElementById("page_firsthalf");
    if (!IsElementValid(s_FirstHalfPage))
    {
        console.error("could not get first half round paage.");
        return false;
    }

    // Get the half time page
    var s_HalfTimePage = document.getElementById("page_halftime");
    if (!IsElementValid(s_HalfTimePage))
    {
        console.error("could not get the half time page.");
        return false;
    }

    // Get the second half page
    var s_SecondHalfPage = document.getElementById("page_secondhalf");
    if (!IsElementValid(s_SecondHalfPage))
    {
        console.error("could not get second half page.");
        return false;
    }

    // Get the timeout page
    var s_TimeoutPage = document.getElementById("page_timeout");
    if (!IsElementValid(s_TimeoutPage))
    {
        console.error("could not get timeout page.");
        return false;
    }

    // Get the strat time page
    var s_StratPage = document.getElementById("page_timeout");
    if (!IsElementValid(s_StratPage))
    {
        console.error("could not get strat page.");
        return false;
    }

    // Get the nadetraining page
    var s_NadeTrainingPage = document.getElementById("page_nadetraining");
    if (!IsElementValid(s_NadeTrainingPage))
    {
        console.error("could not get the nadetraining page.");
        return false;
    }
}