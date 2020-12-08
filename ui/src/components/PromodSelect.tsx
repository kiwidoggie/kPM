import React from "react";
import Select from 'react-select';
import { selectStyle } from "../helpers/SelectStyle";
import { selectSmallStyle } from "../helpers/SelectSmallStyle";

interface Props {
    type: string;
    options: any;
    defaultValue: any;
    small: boolean;
    onChangeSelected: (slot: string, weapon: string) => void;
    selectValue: any;
}

const PromodSelect: React.FC<Props> = ({ options, defaultValue, small, type, onChangeSelected, selectValue }) => {
    const handleChange = (event: any) => {
        onChangeSelected(type, event.value);
    }

    return (
        <>
            <Select 
                options={options} 
                styles={small ? selectSmallStyle : selectStyle} 
                isSearchable={false}
                value={selectValue}
                onChange={handleChange}
                />
        </>
    );
};

export default PromodSelect;
