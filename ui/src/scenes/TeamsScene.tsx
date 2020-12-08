import React from "react";
import Title from "../components/Title";
import { Teams } from "../helpers/Teams";

import './TeamsScene.scss';

interface Props {
    show: boolean;
    selectedTeam: Teams;
    setSelectedTeam: (team: Teams) => void;
}

const TeamsScene: React.FC<Props> = ({ show, selectedTeam, setSelectedTeam }) => {
    const setTeam = (team: Teams) => {
        setSelectedTeam(team);

        if (navigator.userAgent.includes('VeniceUnleashed')) {
            console.log('DispatchEventLocal . WebUISetSelectedTeam . ' + team);
            WebUI.Call('DispatchEventLocal', 'WebUISetSelectedTeam', team);
        }
    }

    return (
        <>
            {show &&
                <div id="pageTeams" className="page">
                    <Title text="Select a team"/>
                    <div className="teamsList">
                        <button className={"btn border-btn primary"} onClick={() => setTeam(Teams.Attackers)}>Attackers</button>
                        <button className={"btn border-btn secondary"} onClick={() => setTeam(Teams.Defenders)}>Defenders</button>
                        <hr/>
                        <button className={"btn border-btn"} onClick={() => setTeam(Teams.Defenders)}>Spectator</button>
                    </div>
                </div>
            }
        </>
    );
};

export default TeamsScene;
