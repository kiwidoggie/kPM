import React from "react";
import { Teams } from "../helpers/Teams";
import { Fade } from "react-awesome-reveal";

import './EndgameScene.scss';

interface Props {
    roundWon: boolean;
    winningTeam: Teams;
    teamAttackersScore: number;
    teamDefendersScore: number;
}

const EndgameScene: React.FC<Props> = ({ roundWon, winningTeam, teamAttackersScore, teamDefendersScore }) => {
    return (
        <>
            <Fade duration={500} triggerOnce={true}>
                <div id="page_endgame" className="page"> 
                    <div className={"header " + ((winningTeam === Teams.Attackers) ? 'attackers' : 'defenders')}>
                        <h2>Round {roundWon ? 'Won' : 'Lost'}</h2>
                        <h1>{(winningTeam === Teams.Attackers) ? 'Attackers' : 'Defenders'} eliminated</h1>
                    </div>
                </div>
            </Fade>
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
