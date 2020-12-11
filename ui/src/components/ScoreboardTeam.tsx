import React from "react";
import { Player } from "../helpers/Player";
import { Teams } from "../helpers/Teams";
import ScoreboardPlayer from "./ScoreboardPlayer";

interface Props {
    team: Teams;
    score: number;
    players?: Player[];
}

const ScoreboardTeam: React.FC<Props> = ({ team, score, players }) => {
    return (
        <>
            <div className={"team " + ((team === Teams.Attackers) ? 'attackers' : 'defenders')}>
                <div className="headerBar">
                    <div className="teamName">{(team === Teams.Attackers) ? 'Attackers' : 'Defenders'}</div>
                    <div className="point">{score??0}</div>
                </div>
                <div className="playersHolderHeader">
                    <div className="playerPing">Ping</div>
                    <div className="playerName">Name</div>
                    <div className="playerKill">Kill</div>
                    <div className="playerDeath">Death</div>
                </div>
                <div className="playersHolder">
                    <div className="playersHolderInner">
                        {(players !== undefined && players.length > 0)
                        ?
                            players.map((player: Player, key: number) => (
                                <ScoreboardPlayer player={player} key={key} />
                            ))
                        :
                            <div className="noPlayers">No players...</div>
                        }
                    </div>
                </div>
            </div>
        </>
    );
};

export default ScoreboardTeam;
