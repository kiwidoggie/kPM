import React from "react";
import { GameStates, GameStatesRoundString } from "./helpers/GameStates";

import './Header.scss';

interface Props {
    teamAttackersScore: number;
    teamDefendersScore: number;
    teamAttackersClan?: string;
    teamDefendersClan?: string;
    currentScene: GameStates;
    round: string|null;
    showHud: boolean;
}

const Header: React.FC<Props> = ({ teamAttackersClan, teamDefendersClan, teamAttackersScore, teamDefendersScore, currentScene, round, showHud }) => {
    return (
        <>
            <div id="promodHeader">
                Promod
            </div>

            {showHud &&
                <div id="inGameHeader" className="fadeInTop">
                    {teamAttackersClan 
                    ?
                        <div id="teamAttackers">
                            {teamAttackersClan}
                        </div>
                    :
                        <div></div>
                    }
                    <div id="score">
                        <div id="scoreAttackers">
                            <span id="team">Attackers</span>
                            <span id="points">{teamAttackersScore??0}</span>
                        </div>
                        <div id="roundTimer">
                            <span id="timer">00:00</span>
                            <span id="round">
                                {GameStatesRoundString[currentScene].replace('{round}', (round??'0'))??''}
                            </span>
                        </div>
                        <div id="scoreDefenders">
                            <span id="team">Defenders</span>
                            <span id="points">{teamDefendersScore??0}</span>
                        </div>
                    </div>
                    {teamDefendersClan 
                    ?
                        <div id="teamDefenders">
                            {teamDefendersClan}
                        </div>
                    :
                        <div></div>
                    }
                </div>
            }
        </>
    );
};

Header.defaultProps = {
    currentScene: GameStates.None,
    teamAttackersScore: 0,
    teamDefendersScore: 0,
    round: '0',
};


export default Header;
