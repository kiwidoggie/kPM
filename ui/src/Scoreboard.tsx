import React from "react";
import ScoreboardTeam from "./components/ScoreboardTeam";
import { Players } from "./helpers/Player";
import { Teams } from "./helpers/Teams";

import './Scoreboard.scss';

interface Props {
    showScoreboard: boolean;
    teamAttackersScore: number;
    teamDefendersScore: number;
    players: Players;
}

const Scoreboard: React.FC<Props> = ({ showScoreboard, teamAttackersScore, teamDefendersScore, players }) => {
    return (
        <>
            {showScoreboard &&
                <div id="inGameScoreboard" className="fadeInBottom">
                    <ScoreboardTeam team={Teams.Attackers} score={teamAttackersScore} players={players[Teams.Attackers]} />
                    <ScoreboardTeam team={Teams.Defenders} score={teamDefendersScore} players={players[Teams.Defenders]} />
                </div>
            }
        </>
    );
};

Scoreboard.defaultProps = {
    showScoreboard: false,
};


export default Scoreboard;
