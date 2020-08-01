g_USKits = {
    Assault = {
        -- Name/Display Name of this class
        name = "Assault",

        -- The headgear for this class
        headGear = "us_helmet08",

        -- Head for the class
        head = "sp_campo",

        -- Upper body model
        upperBody = "us_upperbody04",

        -- Lower body model
        lowerBody = "us_lowerbody03",

        -- How many of these can be on a team
        teamLimitation = 127,

        -- The weapon loadout
        weapons = {
            [1] = {
                type = WeaponDefinitions.AK74M,
                magazineCount = 9,
                optics = { WeaponAttachments.IronSights },
                underRailAttachments = { WeaponAttachments.AK47M.Foregrip }
            },
            [2] = {
                type = WeaponDefinitions.M9,
                magazineCount = 3
            },
            [4] = {
                type = WeaponDefinitions.Knife
            },
            [5] = {
                type = WeaponDefinitions.Grenade,
                magazineCount = 1
            },
            [6] = {
                type = WeaponDefinitions.Flashbang,
                magazineCount = 1
            }
        },
        orderId = 1
    },
    SpecOps = {

    },
    Demo = {

    },
    Sniper = {

    },
    Debug = {

    }
}