import React from "react";
import { Player } from "../helpers/Player";

interface Props {
    player: Player;
}

const ScoreboardPlayer: React.FC<Props> = ({ player }) => {
    return (
        <>
            <div className={"playerHolder " + (player.isDead ? 'isDead' : '')}>
                <div className="playerPing">{player.ping??0}</div>
                <div className="playerName">{player.name??' - '}</div>
                <div className="playerKill">{player.kill??' - '}</div>
                <div className="playerDeath">{player.death??' - '}</div>
            </div>
        </>
    );
};

export default ScoreboardPlayer;
