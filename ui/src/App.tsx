import React, { useState } from "react";

import Header from "./Header";
import Scoreboard from "./Scoreboard";

import RoundEndInfoBox from "./components/RoundEndInfoBox";

import TeamsScene from "./scenes/TeamsScene";
import WarmupScene from "./scenes/WarmupScene";
import KnifeRoundScene from "./scenes/KnifeRoundScene";
import LoadoutScene from "./scenes/LoadoutScene";

import { GameStates } from './helpers/GameStates';
import { Teams } from "./helpers/Teams";
import { Player, Players } from "./helpers/Player";


import './Animations.scss';
import './Global.scss';
import GameEndInfoBox from "./components/GameEndInfoBox";

const App: React.FC = () => {
    /*
    * Debug
    */
    let debugMode: boolean = false;
    if (!navigator.userAgent.includes('VeniceUnleashed')) {
        if (window.location.ancestorOrigins === undefined || window.location.ancestorOrigins[0] !== 'webui://main') {
            debugMode = true;
        }
    }

    /*
    * Local States
    */
    const [scene, setScene] = useState<GameStates>(GameStates.None);

    window.ChangeState = function (p_GameState: GameStates) {
        setScene(p_GameState);

        if (p_GameState !== GameStates.None && showHud !== true) {
            setShowHud(true)
        }
    }

    /*
    * Global States 
    */
    const [showHud, setShowHud] = useState<boolean>(false);

    const [round, setRound] = useState<number>(0);
    const [roundWon, setRoundWon] = useState<boolean>(false);
    const [winningTeam, setWinningTeam] = useState<Teams>(Teams.Attackers);
    const [teamAttackersScore, setTeamAttackersScore] = useState<number>(0);
    const [teamDefendersScore, setTeamDefendersScore] = useState<number>(0);

    window.UpdateHeader = function (p_AttackerPoints: number, p_DefenderPoints: number, p_Rounds: number) {
        setTeamAttackersScore(p_AttackerPoints);
        setTeamDefendersScore(p_DefenderPoints);
        setRound(p_Rounds);
    }

    const [showTeamsPage, setShowTeamsPage] = useState<boolean>(false);
    const [selectedTeam, setSelectedTeam] = useState<Teams>(Teams.None);
    const [showScoreboard, setShowScoreboard] = useState<boolean>(false);

    const setTeam = (team: Teams) => {
        setShowTeamsPage(false);
        setSelectedTeam(team);
        setShowLoadoutPage(true);
    }

    window.OpenCloseTeamMenu = function (forceOpen?: boolean) {
        if (showLoadoutPage) {
            setShowLoadoutPage(false);
        }

        if (showScoreboard) {
            setShowScoreboard(false);
        }

        if (!showTeamsPage) {
            WebUI.Call('DisableKeyboard');
            WebUI.Call('EnableMouse');
        } else {
            WebUI.Call('ResetKeyboard');
            WebUI.Call('ResetMouse');
        }

        if(forceOpen) {
            setShowTeamsPage(true);
        } else {
            setShowTeamsPage(prevState => !prevState);
        }
    }

    const [showLoadoutPage, setShowLoadoutPage] = useState<boolean>(false);

    window.OpenCloseLoadoutMenu = function () {
        if (showTeamsPage) {
            setShowTeamsPage(false);
        }

        if (showScoreboard) {
            setShowScoreboard(false);
        }

        if (!showLoadoutPage) {
            WebUI.Call('DisableKeyboard');
            WebUI.Call('EnableMouse');
        } else {
            WebUI.Call('ResetKeyboard');
            WebUI.Call('ResetMouse');
        }

        setShowLoadoutPage(prevState => !prevState);
    }


    const [showRoundEndInfoBox, setShowRoundEndInfoBox] = useState<boolean>(false);

    window.ShowHideRoundEndInfoBox = function (open: boolean) {
        setShowRoundEndInfoBox(open);
    }

    window.UpdateRoundEndInfoBox = function (p_RoundWon: boolean, p_WinningTeam: string) {
        setRoundWon(p_RoundWon);
        if(p_WinningTeam === 'attackers') {
            setWinningTeam(Teams.Attackers);
        } else {
            setWinningTeam(Teams.Defenders);
        }
    }

    const [gameWon, setGameWon] = useState<boolean|null>(null);
    const [gameWinningTeam, setGameWinningTeam] = useState<Teams|null>(null);
    window.SetGameEnd = function (p_GameWon: boolean, p_WinningTeam: string) {
        setGameWon(p_GameWon);
        if(p_WinningTeam === 'attackers') {
            setGameWinningTeam(Teams.Attackers);
        } else if(p_WinningTeam === 'defenders') {
            setGameWinningTeam(Teams.Defenders);
        }
    }
    
    window.OpenCloseScoreboard = function (open: boolean) {
        if (!showTeamsPage && !showLoadoutPage) {
            setShowScoreboard(open);
        }
    }

    const [players, setPlayers] = useState<Players>({
        [Teams.Attackers]: [],
        [Teams.Defenders]: [],
    });

    const [clientPlayer, setClientPlayer] = useState<Player>({
        id: 0,
        name: '',
        ping: 0,
        kill: 0,
        death: 0,
        isDead: false,
        isReady: false,
        team: Teams.None,
    });

    window.UpdatePlayers = function (p_Players: any, p_ClientPlayer: any) {
        setClientPlayer(p_ClientPlayer);
        setPlayers({
            [Teams.Attackers]: p_Players["attackers"],
            [Teams.Defenders]: p_Players["defenders"],
        });
    }

    const [rupProgress, setRupProgress] = useState<number>(0);
    window.RupInteractProgress = function(m_RupHeldTime: number, MaxReadyUpTime: number) {
        setRupProgress(Math.round(m_RupHeldTime / MaxReadyUpTime * 100));
    }

    const GameStatesPage = () => {
        switch (scene) {
            default:
            case GameStates.None:
                return <></>;

            case GameStates.WarmupToKnife:
            case GameStates.Warmup:
                return <WarmupScene rupProgress={rupProgress} players={players} clientPlayer={clientPlayer} />;

            case GameStates.KnifeRound:
                return <KnifeRoundScene />;

            /*case GameStates.EndGame:
                return <EndgameScene
                    roundWon={roundWon}
                    winningTeam={winningTeam}
                    teamAttackersScore={teamAttackersScore}
                    teamDefendersScore={teamDefendersScore}
                />;*/
        }
    }

    return (
        <div className="App">
            
            {debugMode &&
                <style dangerouslySetInnerHTML={{__html: `
                    #debug {
                        display: block !important;
                    }
                `}} />
            }
            
            <div id="debug" className="global">
                <button onClick={() => setScene(GameStates.Warmup)}>Warmup</button>
                {/*<button onClick={() => setScene(GameStates.EndGame)}>EndGame</button>*/}
                <button onClick={() => setScene(GameStates.Strat)}>Strat</button>
                <button onClick={() => setShowHud(prevState => !prevState)}>ShowHeader On / Off</button>
                <button onClick={() => setShowScoreboard(prevState => !prevState)}>Scoreboard On / Off</button>
                <button onClick={() => setShowRoundEndInfoBox(prevState => !prevState)}>RoundEndInfo On / Off</button>
                <button onClick={() => setGameWon(true)}>setGameWon</button>
                <button onClick={() => setGameWinningTeam(Teams.Attackers)}>Attackers won the game</button>
                <br />
                <button onClick={() => setRoundWon(true)}>Win</button>
                <button onClick={() => setRoundWon(false)}>Lose</button>
                <button onClick={() => setWinningTeam(Teams.Attackers)}>Attackers Win</button>
                <button onClick={() => setWinningTeam(Teams.Defenders)}>Defenders Win</button>
                <button onClick={() => setTeamAttackersScore(prevState => prevState + 1)}>Attackers +1</button>
                <button onClick={() => setTeamDefendersScore(prevState => prevState + 1)}>Defenders +1</button>
            </div>

            <div className="window">
                <Header
                    showHud={showHud}
                    currentScene={scene}
                    teamAttackersScore={teamAttackersScore}
                    teamDefendersScore={teamDefendersScore}
                    teamAttackersClan=""
                    teamDefendersClan=""
                    round={round}
                />
                <GameStatesPage />
                <TeamsScene
                    show={showTeamsPage}
                    selectedTeam={selectedTeam}
                    setSelectedTeam={(team: Teams) => setTeam(team)}
                />
                <LoadoutScene
                    show={showLoadoutPage}
                    setShowLoadoutPage={(show) => setShowLoadoutPage(show)}
                />
                <Scoreboard 
                    showScoreboard={showScoreboard}
                    teamAttackersScore={teamAttackersScore}
                    teamDefendersScore={teamDefendersScore}
                    players={players}
                    gameState={scene}
                />

                {gameWon !== null 
                ?
                    <GameEndInfoBox
                        gameWon={gameWon}
                        winningTeam={gameWinningTeam}
                        />
                :
                    <>
                        {showRoundEndInfoBox &&
                            <RoundEndInfoBox 
                                roundWon={roundWon}
                                winningTeam={winningTeam}
                                afterDisaper={() => setShowRoundEndInfoBox(false)}
                                />
                        }
                    </>
                }
            </div>
        </div>
    );
};

export default App;

declare global {
    interface Window {
        ChangeState: (p_GameState: GameStates) => void;
        //UpdateRoundEndStatus: (p_RoundWon: boolean, p_WinningTeam: Teams, p_Team1Score: number, p_Team2Score: number) => void;
        OpenCloseLoadoutMenu: () => void;
        OpenCloseTeamMenu: (forceOpen?: boolean) => void;
        UpdatePlayers: (p_Players: any, p_ClientPlayer: any) => void;
        OpenCloseScoreboard: (open: boolean) => void;
        RupInteractProgress: (m_RupHeldTime: number, MaxReadyUpTime: number) => void
        UpdateHeader: (p_AttackerPoints: number, p_DefenderPoints: number, p_Rounds: number) => void;
        ShowHideRoundEndInfoBox: (open: boolean) => void;
        UpdateRoundEndInfoBox: (p_RoundWon: boolean, p_WinningTeam: string) => void;
        SetGameEnd: (p_GameWon: boolean, p_WinningTeam: string) => void;
    }
}
