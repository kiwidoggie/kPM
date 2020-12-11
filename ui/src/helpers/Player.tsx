import { Teams } from "./Teams";

export interface Player {
    id?: number,
    name: string;
    ping: number;
    kill: number;
    death: number;
    isDead: boolean;
};

export interface Players {
    [Teams.Attackers]: Player[],
    [Teams.Defenders]: Player[],
}
