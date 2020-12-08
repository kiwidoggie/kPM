import React from "react";

import './Title.scss';

interface Props {
    text?: string;
}

const Title: React.FC<Props> = ({ text }) => {
    return (
        <>
            <div className="header">
                <h1>{text??''}</h1>
            </div>
        </>
    );
};

export default Title;
