/*
    I hate javascript with a burning passion
    I'm pretty sure that web developers are masochistic
    like someone come get they mans.

    kPM.js
    Library for managing the WebUI of kPM mod
*/

/**
 * 
 */
const ReadyStatus =
{
    NotReady: 0,
    Ready: 1
}

/**
 * List of Page ID's.
 * 
 * These must match Shared/GameStates.lua
 */
const GameStates =
{
    None: 0,
    Warmup: 1,
    WarmupToKnife: 2,
    KnifeRound: 3,
    KnifeToFirst: 4,
    FirstHalf: 5,
    FirstToHalf: 6,
    HalfTime: 7,
    HalfToSecond: 8,
    SecondHalf: 9,
    Timeout: 10,
    Strat: 11,
    NadeTraining: 12,
    EndGame: 13
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
    WarmupToKnife: "page_warmuptoknife",
    KnifeRound: "page_kniferound",
    KnifeToFirst: "page_knifetofirst",
    FirstHalf: "page_firsthalf",
    FirstToHalf: "page_firsttohalf",
    HalfTime: "page_halftime",
    HalfToSecond: "page_halftosecond",
    SecondHalf: "page_secondhalf",
    Timeout: "page_timeout",
    Start: "page_strat",
    NadeTraining: "page_nadetraining",
    EndGame: "page_endgame"
}

/**
 * Update the endgame page.
 * 
 * @param {bool} p_RoundWon 
 * @param {TeamId/int} p_WinningTeam 
 * @param {int} p_Team1Score 
 * @param {int} p_Team2Score 
 */
function UpdateRoundEndStatus(p_RoundWon, p_WinningTeam, p_Team1Score, p_Team2Score)
{
    // Get the round state element
    var s_RoundState = document.getElementById("round_state");
    if (!IsElementValid(s_RoundState))
    {
        console.error("could not get round_state.");
        return false;
    }

    // Get the round winner state
    var s_RoundWinnerState = document.getElementById("round_winner_state");
    if (!IsElementValid(s_RoundWinnerState))
    {
        console.error("could not get the round winner state.");
        return false;
    }

    // Get the team1 score
    var s_RoundTeam1Score = document.getElementById("round_team1_score");
    if (!IsElementValid(s_RoundTeam1Score))
    {
        console.error("could not get the round team1 score.");
        return false;
    }

    // Get the team2 score
    var s_RoundTeam2Score = document.getElementById("round_team2_score");
    if (!IsElementValid(s_RoundTeam2Score))
    {
        console.error("could not get the round team2 score.");
        return false;
    }

    // Update if we won or lost the round
    if (p_RoundWon)
        s_RoundState.innerText = "Win";
    else
        s_RoundState.innerText = "Loss";
    
    // Update the winning team
    if (p_WinningTeam == 1)
        s_RoundWinnerState.innerText = "Attackers";
    else
        s_RoundWinnerState.innerText = "Defenders";
    
    // Update the round scores
    s_RoundTeam1Score.innerText = p_Team1Score;
    s_RoundTeam2Score.innerText = p_Team2Score;

    return true;
}

/**
 * Update WebUI ready up players and state
 * 
 * @param {int} p_WaitingOnPlayers 
 * @param {bool} p_LocalRupStatus 
 */
function UpdateRupStatus(p_WaitingOnPlayers, p_LocalRupStatus)
{
    // Get the ready-up state
    var s_RupState = document.getElementById("rup_state");
    if (!IsElementValid(s_RupState))
    {
        console.error("could not get rup_state.");
        return false;
    }

    // Get the currently readied up count
    var s_RupCount = document.getElementById("rup_count");
    if (!IsElementValid(s_RupCount))
    {
        console.error("could not get rup_count.");
        return false;
    }

    // Update the text accordingly
    if (p_LocalRupStatus)
    {
        s_RupState.innerText = "Un-Ready";
    }
    else
    {
        s_RupState.innerText = "Ready-Up";
    }

    s_RupCount.innerText = p_WaitingOnPlayers;

    return true;
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