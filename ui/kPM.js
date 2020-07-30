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

/**
 * Checks if an element is valid.
 * 
 * This will check if an element is not null or undefined
 * 
 * @param {div} p_Element 
 */
function IsElementValid(p_Element)
{
    return p_Element != null && p_Element != undefined;
}

/**
 * Changes gamestate.
 * 
 * This changes the gamestate within javascript and hides/shows the required pages
 * @param {GameStates} p_GameState 
 */
function ChangeState(p_GameState)
{
    // Validate that our index is within the bounds
    if (p_GameState < GameStates.None || p_GameState > GameStates.EndGame)
    {
        console.error("invalid gamestate index.");
        return false;
    }

    // Iterate through all of the pages and make sure that they exist
    var s_StateIndex = GameStates.None;
    for (const [l_StateName, l_StatePage] of Object.entries(GameStatesPages))
    {
        // We want to skip the none state because it should never be used
        if (s_StateIndex == GameStates.None)
        {
            s_StateIndex += 1;
            continue;
        }
        
        // Get the page div
        var l_Page = document.getElementById(l_StatePage);
        if (!IsElementValid(l_Page))
        {
            console.error("could not load page", l_StatePage);
            return false;
        }
        
        // Debugging information
        //console.log(s_StateIndex, l_StateName, l_StatePage);

        if (s_StateIndex == p_GameState)
            l_Page.style.display = "unset";
        else
            l_Page.style.display = "none";

        // Increment the state index
        s_StateIndex += 1;
    }

    return true;
}