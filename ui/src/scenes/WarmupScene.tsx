import React, { useState } from "react";
import './WarmupScene.scss';

const WarmupScene: React.FC = () => {
    const [rupCount, setRupCount] = useState<number|null>(2);
    const [rupState, setRupState] = useState<boolean>(false);
    const [rupProgress, setRupProgress] = useState<number>(0);

    window.UpdateRupStatus = function(p_WaitingOnPlayers: number, p_LocalRupStatus: boolean) {
        console.log(p_WaitingOnPlayers, p_LocalRupStatus);
        setRupState(p_LocalRupStatus);
        setRupCount(p_WaitingOnPlayers);
    }

    window.RupInteractProgress = function(m_RupHeldTime: number, MaxReadyUpTime: number) {
        setRupProgress(Math.round(m_RupHeldTime / MaxReadyUpTime * 100));
    }

    return (
        <>
            <div id="pageWarmup" className="page">
                <div className={"infoBox " + (rupCount === 0 ? "ready" : "notReady")}>
                    <div className="rupProgress" style={{width: rupProgress + "%"}}></div>
                    {rupCount !== null &&
                        <>
                            {rupCount > 0
                            ?
                                <>
                                    <h1>Hold <span className="key">{"{Interact}"}</span> to <span>{rupState ? 'Un-Ready' : 'Ready-Up'}</span></h1>
                                    <h3>Waiting on <span>{rupCount ?? 0}</span> Player(s)</h3>
                                </>
                            :
                                <>
                                    <h2>All players are ready, starting knife round...</h2>
                                </>
                            }
                        </>
                    }
                </div>
            </div>
        </>
    );
};

export default WarmupScene;

declare global {
    interface Window {
        UpdateRupStatus: (p_WaitingOnPlayers: number, p_LocalRupStatus: boolean) => void;
        RupInteractProgress: (m_RupHeldTime: number, MaxReadyUpTime: number) => void
    }
}
