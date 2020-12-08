import React, { useState } from "react";

import Header from "./Header";
import TeamsScene from "./scenes/TeamsScene";
import WarmupScene from "./scenes/WarmupScene";
import EndgameScene from "./scenes/EndgameScene";
import KnifeRoundScene from "./scenes/KnifeRoundScene";
import LoadoutScene from "./scenes/LoadoutScene";

import { GameStates } from './helpers/GameStates';
import { Teams } from "./helpers/Teams";

import './Animations.scss';
import './Global.scss';

const App: React.FC = () => {
    /*
    * Local States
    */
    const [scene, setScene] = useState<GameStates>(GameStates.None);

    window.ChangeState = function(p_GameState: GameStates) {
        setScene(p_GameState);

        if(p_GameState !== GameStates.None && showHud !== true) {
            setShowHud(true)
        }
    }

    /*
    * Global States 
    */
    const [showHud, setShowHud] = useState<boolean>(false);

    /*window.OpenCloseHud = function() {
        setShowHud(prevState => !prevState);
    }*/

    const [roundWon, setRoundWon] = useState<boolean>(false);
    const [winningTeam, setWinningTeam] = useState<Teams>(Teams.Attackers);
    const [teamAttackersScore, setTeamAttackersScore] = useState<number>(0);
    const [teamDefendersScore, setTeamDefendersScore] = useState<number>(0);

    const [showTeamsPage, setShowTeamsPage] = useState<boolean>(false);
    const [selectedTeam, setSelectedTeam] = useState<Teams>(Teams.None);

    const setTeam = (team: Teams) => {
        setShowTeamsPage(false);
        setSelectedTeam(team);
        setShowLoadoutPage(true);
    }

    window.OpenCloseTeamMenu = function() {
        if(showLoadoutPage) {
            setShowLoadoutPage(false);
        }

        if(!showTeamsPage) {
            WebUI.Call('DisableKeyboard');
            WebUI.Call('EnableMouse');
        } else {
            WebUI.Call('ResetKeyboard');
            WebUI.Call('ResetMouse');
        }

        setShowTeamsPage(prevState => !prevState);
    }

    const [showLoadoutPage, setShowLoadoutPage] = useState<boolean>(false);

    window.OpenCloseLoadoutMenu = function() {
        if(showTeamsPage) {
            setShowTeamsPage(false);
        }

        if(!showLoadoutPage) {
            WebUI.Call('DisableKeyboard');
            WebUI.Call('EnableMouse');
        } else {
            WebUI.Call('ResetKeyboard');
            WebUI.Call('ResetMouse');
        }

        setShowLoadoutPage(prevState => !prevState);
    }

    window.UpdateRoundEndStatus = function(p_RoundWon: boolean, p_WinningTeam: Teams, p_Team1Score: number, p_Team2Score: number) {
        setRoundWon(p_RoundWon);
        setWinningTeam(p_WinningTeam);
        setTeamAttackersScore(p_Team1Score);
        setTeamDefendersScore(p_Team2Score);
    }

    const GameStatesPage = () => {
        switch(scene) {
            default: 
            case GameStates.None:
                return <></>;

            case GameStates.WarmupToKnife:
            case GameStates.Warmup:
                return <WarmupScene />;
            
            case GameStates.KnifeRound:
                return <KnifeRoundScene />;

            case GameStates.EndGame:
                return <EndgameScene 
                        roundWon={roundWon} 
                        winningTeam={winningTeam} 
                        teamAttackersScore={teamAttackersScore} 
                        teamDefendersScore={teamDefendersScore} 
                    />;
        }
    }

    return (
        <div className="App">

            {/* TODO: Delete me */}
            <div id="debug" className="global">
                <button onClick={() => setScene(GameStates.Warmup)}>Warmup</button>
                <button onClick={() => setScene(GameStates.EndGame)}>EndGame</button>
                <button onClick={() => setShowHud(prevState => !prevState)}>ShowHeader On / Off</button>
                <br/>
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
                    round="0"
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
            </div>
        </div>
    );
};

export default App;

declare global {
    interface Window {
        ChangeState: (p_GameState: GameStates) => void;
        UpdateRoundEndStatus: (p_RoundWon: boolean, p_WinningTeam: Teams, p_Team1Score: number, p_Team2Score: number) => void;
        OpenCloseLoadoutMenu: () => void;
        OpenCloseTeamMenu: () => void;
        //OpenCloseHud: () => void;
    }
}
