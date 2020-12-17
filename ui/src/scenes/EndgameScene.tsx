import React from "react";
import { Teams } from "../helpers/Teams";

interface Props {
    roundWon: boolean;
    winningTeam: Teams;
    teamAttackersScore: number;
    teamDefendersScore: number;
}

const EndgameScene: React.FC<Props> = ({ roundWon, winningTeam, teamAttackersScore, teamDefendersScore }) => {
    return (
        <>
            <div id="pageEndgame" className="page"> 
                <div className={"endgameBox " + ((winningTeam === Teams.Attackers) ? 'attackers' : 'defenders')}>
                    <h2>Round {roundWon ? 'Won' : 'Lost'}</h2>
                    <h1>{(winningTeam === Teams.Attackers) ? 'Attackers' : 'Defenders'} eliminated</h1>
                </div>
            </div>
        </>
    );
};

EndgameScene.defaultProps = {
    roundWon: false,
    winningTeam: Teams.Attackers,
    teamAttackersScore: 0,
    teamDefendersScore: 0,
};

export default EndgameScene;
