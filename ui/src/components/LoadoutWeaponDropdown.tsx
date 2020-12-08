import React from "react";

interface Props {
    title?: string;
    weaponName?: string;
    small?: boolean;
    weapons: any,
    onClick: () => void,
    open: boolean,
}

const LoadoutWeaponDropdown: React.FC<Props> = ({ title, weaponName, small, weapons, onClick, open }) => {
    let clickable: boolean = (Object.keys(weapons).length > 1); 
    return (
        <>
            <button onClick={onClick} className={"loadoutWeaponButton " + (small ? 'small ' : '') + ((clickable && open) ? 'secondary ' : '') + (clickable ? 'clickable ' : '') }>
                <h1 className="title">{title??''}</h1>
                <h3 className="weaponName">{weaponName??''}</h3>
            </button>

            {/*(clickable && open) &&
                <div className="loadoutItemWeaponList">
                    {Object.keys(weapons).map((val: string, key: number) => 
                        <button onClick={() => selectWeapon(val)} key={key} className={"loadoutWeaponButton small clickable"}>
                            <h1 className="title">{weapons[val].displayName}</h1>
                        </button>
                    )}
                </div>
            */}
        </>
    );
};

export default LoadoutWeaponDropdown;
