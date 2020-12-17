import React, { useState, useEffect } from "react";

interface Props {
    time: number;
}

const CountDown: React.FC<Props> = ({ time }) => {
    const getMinutesAndSeconds = (time: number) => {
        var minutes = Math.floor(time / 60);
        var seconds = time % 60;
        return [minutes, seconds];
    }
    
    const [[m, s], setTime] = useState(getMinutesAndSeconds(time));

    const tick = () => {
        if (m === 0 && s === 0) {
            return;
        } else if (s === 0) {
            setTime([m - 1, 59]);
        } else {
            setTime([m, s - 1]);
        }
    };

    useEffect(() => {
        const timerID = setInterval(() => tick(), 1000);
        return () => clearInterval(timerID);
    });

    useEffect(() => {
        setTime(getMinutesAndSeconds(time));
    }, [time]);

    return (
        <>
            {`
                ${m.toString().padStart(2, '0')}
                :
                ${s.toString().padStart(2, '0')}
            `}
        </>
    );
};

export default CountDown;
