import React from "react";
import { Teams } from "../helpers/Teams";

interface Props {
    gameWon: boolean|null;
    winningTeam: Teams|null;
}

const GameEndInfoBox: React.FC<Props> = ({ gameWon, winningTeam }) => {
    return (
        <>
            <div className={"roundEndInfoBox gameEndInfoBox fadeInTop " + ((winningTeam !== null ? ((winningTeam === Teams.Attackers) ?  'defenders' : 'attackers') : ''))}>
                {winningTeam !== null
                ?
                    <>
                        <h1>Your team {gameWon ? 'won' : 'lost'}</h1>
                    </>
                :
                    <>
                        <h1>Draw</h1>
                    </>
                }
            </div>
        </>
    );
};

GameEndInfoBox.defaultProps = {
    gameWon: false,
    winningTeam: null,
};

export default GameEndInfoBox;
