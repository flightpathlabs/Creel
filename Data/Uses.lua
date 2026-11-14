local _, ns = ...

-- What each catch turns into: item ID -> the recipes that use it. Also
-- listed: what those recipes make, and what clams hold, where that in
-- turn goes into something.
--
-- Written by tools/make-creel-data.mjs from the game's tables for build
-- 1.60.1.70888 (ItemSparse, ItemEffect, ItemXItemEffect, SpellEffect,
-- SpellReagents, SkillLineAbility, as served by wago.tools), with the
-- classic era build 1.14.4.51829's SkillLineAbility to tell which
-- recipes are new in Forever. Don't edit this by hand: run the script
-- again when the build changes.
--
--   spell       the recipe
--   makes       the item it makes, and count how many
--   profession  the profession it belongs to
--   learn       the skill it's learned at, where a recipe item says so
--               (trainers' levels are kept on the server)
--   yellow      the skill where it turns yellow; green is halfway to grey
--   grey        the skill where it turns grey and stops giving points
--   needs       how many of this item it takes
--   others      the other reagents, item ID -> count
--   forever     true for recipes the original game didn't have

ns.Uses = {
    [4603] = { -- Raw Spotted Yellowtail
        {
            spell = 18238,
            makes = 6887,
            count = 1,
            profession = "cooking",
            learn = 225,
            yellow = 265,
            grey = 305,
            needs = 1,
        }, -- Spotted Yellowtail
        {
            spell = 1225762,
            makes = 238641,
            count = 1,
            profession = "cooking",
            learn = 280,
            yellow = 290,
            grey = 310,
            needs = 12,
            others = { [6362] = 3, [12184] = 4, [239017] = 1 },
            forever = true,
        }, -- Specklefin Feast
    },
    [6289] = { -- Raw Longjaw Mud Snapper
        {
            spell = 7753,
            makes = 4592,
            count = 1,
            profession = "cooking",
            learn = 50,
            yellow = 90,
            grey = 130,
            needs = 1,
        }, -- Longjaw Mud Snapper
    },
    [6291] = { -- Raw Brilliant Smallfish
        {
            spell = 7751,
            makes = 6290,
            count = 1,
            profession = "cooking",
            learn = 1,
            yellow = 45,
            grey = 85,
            needs = 1,
        }, -- Brilliant Smallfish
        {
            spell = 1229745,
            makes = 279967,
            count = 1,
            profession = "fishing",
            yellow = 20,
            grey = 20,
            needs = 1,
            others = { [3371] = 1 },
            forever = true,
        }, -- Fish Bowl
    },
    [6303] = { -- Raw Slitherskin Mackerel
        {
            spell = 7752,
            makes = 787,
            count = 1,
            profession = "cooking",
            learn = 1,
            yellow = 45,
            grey = 85,
            needs = 1,
        }, -- Slitherskin Mackerel
    },
    [6308] = { -- Raw Bristle Whisker Catfish
        {
            spell = 7755,
            makes = 4593,
            count = 1,
            profession = "cooking",
            learn = 100,
            yellow = 140,
            grey = 180,
            needs = 1,
        }, -- Bristle Whisker Catfish
    },
    [6317] = { -- Raw Loch Frenzy
        {
            spell = 7754,
            makes = 6316,
            count = 1,
            profession = "cooking",
            learn = 50,
            yellow = 90,
            grey = 130,
            needs = 1,
            others = { [2678] = 1 },
        }, -- Loch Frenzy Delight
    },
    [6358] = { -- Oily Blackmouth
        {
            spell = 7836,
            makes = 6370,
            count = 1,
            profession = "alchemy",
            yellow = 80,
            grey = 100,
            needs = 2,
            others = { [3371] = 1 },
        }, -- Blackmouth Oil
    },
    [6359] = { -- Firefin Snapper
        {
            spell = 7837,
            makes = 6371,
            count = 2,
            profession = "alchemy",
            yellow = 150,
            grey = 170,
            needs = 2,
            others = { [3371] = 1 },
        }, -- Fire Oil
    },
    [6361] = { -- Raw Rainbow Fin Albacore
        {
            spell = 7827,
            makes = 5095,
            count = 1,
            profession = "cooking",
            learn = 50,
            yellow = 90,
            grey = 130,
            needs = 1,
        }, -- Rainbow Fin Albacore
    },
    [6362] = { -- Raw Rockscale Cod
        {
            spell = 7828,
            makes = 4594,
            count = 1,
            profession = "cooking",
            learn = 175,
            yellow = 190,
            grey = 230,
            needs = 1,
        }, -- Rockscale Cod
        {
            spell = 1225762,
            makes = 238641,
            count = 1,
            profession = "cooking",
            learn = 280,
            yellow = 290,
            grey = 310,
            needs = 3,
            others = { [4603] = 12, [12184] = 4, [239017] = 1 },
            forever = true,
        }, -- Specklefin Feast
    },
    [6522] = { -- Deviate Fish
        {
            spell = 8238,
            makes = 6657,
            count = 1,
            profession = "cooking",
            learn = 85,
            yellow = 125,
            grey = 165,
            needs = 1,
            others = { [2678] = 1 },
        }, -- Savory Deviate Delight
        {
            spell = 8240,
            makes = 6662,
            count = 1,
            profession = "alchemy",
            learn = 90,
            yellow = 120,
            grey = 160,
            needs = 1,
            others = { [2449] = 1, [3371] = 1 },
        }, -- Elixir of Giant Growth
    },
    [7070] = { -- Elemental Water
        {
            spell = 17575,
            makes = 13456,
            count = 1,
            profession = "alchemy",
            learn = 290,
            yellow = 305,
            grey = 345,
            needs = 1,
            others = { [8925] = 1, [13463] = 1 },
        }, -- Greater Frost Protection Potion
    },
    [7080] = { -- Essence of Water
        {
            spell = 17562,
            makes = 7082,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 275,
            grey = 290,
            needs = 1,
        }, -- Essence of Air
        {
            spell = 17564,
            makes = 12808,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 275,
            grey = 290,
            needs = 1,
        }, -- Essence of Undeath
        {
            spell = 17632,
            makes = 13503,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 315,
            grey = 330,
            needs = 8,
            others = { [7076] = 8, [7078] = 8, [7082] = 8, [9262] = 2, [12803] = 8, [13468] = 4 },
        }, -- Alchemist's Stone
    },
    [8365] = { -- Raw Mithril Head Trout
        {
            spell = 1262990,
            makes = 279965,
            count = 1,
            profession = "fishing",
            learn = 140,
            yellow = 140,
            grey = 145,
            needs = 2,
            others = { [4470] = 2, [8925] = 1 },
            forever = true,
        }, -- Fishing Rack
        {
            spell = 20916,
            makes = 8364,
            count = 1,
            profession = "cooking",
            learn = 175,
            yellow = 215,
            grey = 255,
            needs = 1,
        }, -- Mithril Head Trout
    },
    [8959] = { -- Raw Spinefin Halibut
        {
            spell = 1247741,
            makes = 8957,
            count = 1,
            profession = "cooking",
            yellow = 210,
            grey = 220,
            needs = 1,
            forever = true,
        }, -- Spinefin Halibut
    },
    [13422] = { -- Stonescale Eel
        {
            spell = 17551,
            makes = 13423,
            count = 2,
            profession = "alchemy",
            yellow = 250,
            grey = 260,
            needs = 1,
            others = { [3372] = 1 },
        }, -- Stonescale Oil
    },
    [13754] = { -- Raw Glossy Mightfish
        {
            spell = 18239,
            makes = 13927,
            count = 1,
            profession = "cooking",
            learn = 225,
            yellow = 265,
            grey = 305,
            needs = 1,
            others = { [3713] = 1 },
        }, -- Cooked Glossy Mightfish
    },
    [13755] = { -- Raw Winter Squid
        {
            spell = 18240,
            makes = 13928,
            count = 1,
            profession = "cooking",
            learn = 240,
            yellow = 280,
            grey = 320,
            needs = 1,
            others = { [3713] = 1 },
        }, -- Grilled Squid
    },
    [13756] = { -- Raw Summer Bass
        {
            spell = 18242,
            makes = 13929,
            count = 1,
            profession = "cooking",
            learn = 240,
            yellow = 280,
            grey = 320,
            needs = 1,
            others = { [2692] = 2 },
        }, -- Hot Smoked Bass
    },
    [13758] = { -- Raw Redgill
        {
            spell = 18241,
            makes = 13930,
            count = 1,
            profession = "cooking",
            learn = 225,
            yellow = 265,
            grey = 305,
            needs = 1,
        }, -- Filet of Redgill
        {
            spell = 470370,
            makes = 232438,
            count = 1,
            profession = "cooking",
            learn = 300,
            yellow = 325,
            grey = 365,
            needs = 1,
            forever = true,
        }, -- Smoked Redgill
    },
    [13759] = { -- Raw Nightfin Snapper
        {
            spell = 18243,
            makes = 13931,
            count = 1,
            profession = "cooking",
            learn = 250,
            yellow = 290,
            grey = 330,
            needs = 1,
            others = { [159] = 1 },
        }, -- Nightfin Soup
    },
    [13760] = { -- Raw Sunscale Salmon
        {
            spell = 18244,
            makes = 13932,
            count = 1,
            profession = "cooking",
            learn = 250,
            yellow = 290,
            grey = 330,
            needs = 1,
        }, -- Poached Sunscale Salmon
    },
    [13888] = { -- Darkclaw Lobster
        {
            spell = 18245,
            makes = 13933,
            count = 1,
            profession = "cooking",
            learn = 275,
            yellow = 315,
            grey = 355,
            needs = 1,
            others = { [159] = 1 },
        }, -- Lobster Stew
        {
            spell = 1225763,
            makes = 238642,
            count = 1,
            profession = "cooking",
            learn = 280,
            yellow = 290,
            grey = 310,
            needs = 12,
            others = { [3404] = 3, [3712] = 4, [239017] = 1 },
            forever = true,
        }, -- Grand Lobster Banquet
        {
            spell = 470359,
            makes = 232436,
            count = 1,
            profession = "cooking",
            learn = 300,
            yellow = 325,
            grey = 365,
            needs = 1,
            others = { [227813] = 1 },
            forever = true,
        }, -- Darkclaw Bisque
    },
    [13889] = { -- Raw Whitescale Salmon
        {
            spell = 18247,
            makes = 13935,
            count = 1,
            profession = "cooking",
            learn = 275,
            yellow = 315,
            grey = 355,
            needs = 1,
            others = { [3713] = 1 },
        }, -- Baked Salmon
    },
    [13890] = { -- Raw Plated Armorfish
        {
            spell = 1319313,
            makes = 286152,
            count = 1,
            profession = "cooking",
            learn = 225,
            yellow = 245,
            grey = 255,
            needs = 1,
            others = { [3713] = 1 },
            forever = true,
        }, -- Plated Armorfish
    },
    [13893] = { -- Large Raw Mightfish
        {
            spell = 18246,
            makes = 13934,
            count = 1,
            profession = "cooking",
            learn = 275,
            yellow = 315,
            grey = 355,
            needs = 1,
            others = { [2692] = 1, [3713] = 1 },
        }, -- Mightfish Steak
    },
    [21071] = { -- Raw Sagefish
        {
            spell = 25704,
            makes = 21072,
            count = 1,
            profession = "cooking",
            learn = 80,
            yellow = 120,
            grey = 160,
            needs = 1,
            others = { [2678] = 1 },
        }, -- Smoked Sagefish
    },
    [21153] = { -- Raw Greater Sagefish
        {
            spell = 25954,
            makes = 21217,
            count = 1,
            profession = "cooking",
            learn = 175,
            yellow = 215,
            grey = 255,
            needs = 1,
            others = { [2692] = 1 },
        }, -- Sagefish Delight
    },
    [5498] = { -- Small Lustrous Pearl
        {
            spell = 1255143,
            makes = 252427,
            count = 1,
            profession = "leatherworking",
            learn = 35,
            yellow = 40,
            grey = 40,
            needs = 1,
            others = { [2318] = 12, [4231] = 2 },
            forever = true,
        }, -- Moonglow Boots
        {
            spell = 1255137,
            makes = 252433,
            count = 1,
            profession = "leatherworking",
            learn = 60,
            yellow = 90,
            grey = 120,
            needs = 1,
            others = { [2318] = 10, [2320] = 1, [4231] = 2, [249427] = 2 },
            forever = true,
        }, -- Wisdom's Leather Belt
        {
            spell = 1257374,
            makes = 253897,
            count = 1,
            profession = "tailoring",
            learn = 60,
            yellow = 85,
            grey = 120,
            needs = 1,
            others = { [2321] = 2, [2997] = 8, [249409] = 2 },
            forever = true,
        }, -- Pearly Boots
        {
            spell = 8322,
            makes = 6709,
            count = 1,
            profession = "leatherworking",
            learn = 65,
            yellow = 90,
            grey = 120,
            needs = 1,
            others = { [2318] = 6, [2320] = 4, [4231] = 1 },
        }, -- Moonglow Vest
        {
            spell = 1255125,
            makes = 252499,
            count = 1,
            profession = "leatherworking",
            learn = 75,
            yellow = 100,
            grey = 125,
            needs = 2,
            others = { [2318] = 12, [2321] = 1, [4231] = 3, [249427] = 2 },
            forever = true,
        }, -- Wisdom's Leather Gloves
        {
            spell = 1255131,
            makes = 252493,
            count = 1,
            profession = "leatherworking",
            learn = 75,
            yellow = 80,
            grey = 80,
            needs = 1,
            others = { [2318] = 16, [4231] = 2 },
            forever = true,
        }, -- Wisdom's Leather Armor
        {
            spell = 1257380,
            makes = 253909,
            count = 1,
            profession = "tailoring",
            learn = 75,
            yellow = 80,
            grey = 80,
            needs = 2,
            others = { [2321] = 4, [2997] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Pearly Gown
        {
            spell = 1257386,
            makes = 253921,
            count = 1,
            profession = "tailoring",
            learn = 75,
            yellow = 100,
            grey = 135,
            needs = 2,
            others = { [2321] = 4, [2997] = 6, [249409] = 3 },
            forever = true,
        }, -- Pearly Gloves
        {
            spell = 3844,
            makes = 4311,
            count = 1,
            profession = "tailoring",
            learn = 80,
            yellow = 105,
            grey = 140,
            needs = 2,
            others = { [2321] = 2, [2997] = 3 },
        }, -- Heavy Woolen Cloak
        {
            spell = 1255116,
            makes = 252444,
            count = 1,
            profession = "leatherworking",
            learn = 85,
            yellow = 110,
            grey = 135,
            needs = 3,
            others = { [2318] = 14, [2321] = 1, [4231] = 4, [249427] = 3 },
            forever = true,
        }, -- Wisdom's Leather Boots
        {
            spell = 1257392,
            makes = 253933,
            count = 1,
            profession = "tailoring",
            learn = 85,
            yellow = 110,
            grey = 145,
            needs = 3,
            others = { [2321] = 4, [4305] = 8, [249409] = 3 },
            forever = true,
        }, -- Pearly Sash
        {
            spell = 6521,
            makes = 5542,
            count = 1,
            profession = "tailoring",
            yellow = 95,
            grey = 130,
            needs = 1,
            others = { [2321] = 2, [2997] = 3 },
        }, -- Pearl-clasped Cloak
        {
            spell = 1255104,
            makes = 252507,
            count = 1,
            profession = "leatherworking",
            learn = 100,
            yellow = 125,
            grey = 150,
            needs = 4,
            others = { [2319] = 8, [2321] = 2, [4233] = 2, [249427] = 4 },
            forever = true,
        }, -- Wisdom's Leather Hood
        {
            spell = 1255110,
            makes = 252503,
            count = 1,
            profession = "leatherworking",
            learn = 100,
            yellow = 105,
            grey = 105,
            needs = 2,
            others = { [2319] = 8, [4231] = 4 },
            forever = true,
        }, -- Wisdom's Leather Pants
        {
            spell = 1257398,
            makes = 253945,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 105,
            grey = 105,
            needs = 4,
            others = { [2321] = 4, [4305] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Pearly Leggings
        {
            spell = 1257404,
            makes = 253957,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 125,
            grey = 160,
            needs = 4,
            others = { [2842] = 1, [4291] = 2, [4305] = 10, [11082] = 2, [249409] = 4 },
            forever = true,
        }, -- Pearly Circlet
        {
            spell = 1255097,
            makes = 252511,
            count = 1,
            profession = "leatherworking",
            learn = 110,
            yellow = 135,
            grey = 160,
            needs = 6,
            others = { [2319] = 10, [2321] = 3, [4233] = 3, [249427] = 6 },
            forever = true,
        }, -- Wisdom's Leather Tunic
        {
            spell = 1257410,
            makes = 253969,
            count = 1,
            profession = "tailoring",
            learn = 110,
            yellow = 130,
            grey = 160,
            needs = 6,
            others = { [2842] = 2, [4291] = 2, [4305] = 12, [11082] = 2, [249409] = 6 },
            forever = true,
        }, -- Pearly Gown
        {
            spell = 1255082,
            makes = 252519,
            count = 1,
            profession = "leatherworking",
            learn = 125,
            yellow = 150,
            grey = 170,
            needs = 8,
            others = { [2319] = 12, [2321] = 3, [4233] = 4, [249427] = 8 },
            forever = true,
        }, -- Wisdom's Leather Leggings
        {
            spell = 1255088,
            makes = 252515,
            count = 1,
            profession = "leatherworking",
            learn = 125,
            yellow = 130,
            grey = 130,
            needs = 3,
            others = { [2319] = 12, [4233] = 2 },
            forever = true,
        }, -- Wisdom's Leather Helm
        {
            spell = 1257417,
            makes = 253983,
            count = 1,
            profession = "tailoring",
            learn = 125,
            yellow = 130,
            grey = 130,
            needs = 6,
            others = { [2321] = 4, [4305] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Pearly Circlet
        {
            spell = 1257423,
            makes = 253995,
            count = 1,
            profession = "tailoring",
            learn = 125,
            yellow = 145,
            grey = 175,
            needs = 8,
            others = { [2321] = 3, [2842] = 2, [4305] = 14, [11082] = 3, [249409] = 8 },
            forever = true,
        }, -- Pearly Leggings
        {
            spell = 23399,
            makes = 18948,
            count = 1,
            profession = "leatherworking",
            learn = 130,
            yellow = 155,
            grey = 175,
            needs = 4,
            others = { [4234] = 8, [4236] = 2, [4461] = 1, [5637] = 4 },
        }, -- Barbaric Bracers
    },
    [5500] = { -- Iridescent Pearl
        {
            spell = 3851,
            makes = 4317,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 125,
            grey = 160,
            needs = 1,
            others = { [2321] = 3, [2997] = 6 },
        }, -- Phoenix Pants
        {
            spell = 3868,
            makes = 4331,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 125,
            grey = 160,
            needs = 1,
            others = { [2321] = 4, [2324] = 2, [2997] = 4 },
        }, -- Phoenix Gloves
        {
            spell = 3855,
            makes = 4320,
            count = 1,
            profession = "tailoring",
            yellow = 125,
            grey = 160,
            needs = 1,
            others = { [2319] = 4, [3182] = 4, [4305] = 2 },
        }, -- Spidersilk Boots
        {
            spell = 1255075,
            makes = 252523,
            count = 1,
            profession = "leatherworking",
            learn = 150,
            yellow = 155,
            grey = 155,
            needs = 1,
            others = { [4233] = 2, [4234] = 8 },
            forever = true,
        }, -- Mender's Leather Belt
        {
            spell = 3778,
            makes = 4262,
            count = 1,
            profession = "leatherworking",
            learn = 160,
            yellow = 180,
            grey = 200,
            needs = 2,
            others = { [1529] = 2, [2321] = 1, [3864] = 1, [4236] = 4 },
        }, -- Gem-studded Leather Belt
        {
            spell = 13628,
            makes = 11130,
            count = 1,
            profession = "enchanting",
            yellow = 175,
            grey = 215,
            needs = 1,
            others = { [11082] = 1, [11083] = 1, [11128] = 1 },
        }, -- Runed Golden Rod
        {
            spell = 1255065,
            makes = 252530,
            count = 1,
            profession = "leatherworking",
            learn = 175,
            yellow = 195,
            grey = 215,
            needs = 2,
            others = { [4234] = 16, [4236] = 2, [4291] = 2, [249427] = 1, [249428] = 2 },
            forever = true,
        }, -- Mender's Leather Gloves
        {
            spell = 1255008,
            makes = 252565,
            count = 1,
            profession = "leatherworking",
            learn = 200,
            yellow = 205,
            grey = 205,
            needs = 2,
            others = { [4233] = 2, [4234] = 8 },
            forever = true,
        }, -- Mender's Mail Boots
        {
            spell = 1255060,
            makes = 252533,
            count = 1,
            profession = "leatherworking",
            learn = 200,
            yellow = 205,
            grey = 205,
            needs = 2,
            others = { [4233] = 2, [4234] = 8 },
            forever = true,
        }, -- Mender's Leather Shoes
        {
            spell = 1255004,
            makes = 252569,
            count = 1,
            profession = "leatherworking",
            learn = 210,
            yellow = 220,
            grey = 240,
            needs = 3,
            others = { [4236] = 3, [4291] = 2, [4304] = 10, [249427] = 2, [249428] = 4 },
            forever = true,
        }, -- Mender's Mail Shoulders
        {
            spell = 1255055,
            makes = 252538,
            count = 1,
            profession = "leatherworking",
            learn = 210,
            yellow = 230,
            grey = 250,
            needs = 3,
            others = { [4236] = 3, [4291] = 2, [4304] = 10, [249427] = 2, [249428] = 4 },
            forever = true,
        }, -- Mender's Leather Shoulders
        {
            spell = 1255000,
            makes = 252573,
            count = 1,
            profession = "leatherworking",
            learn = 225,
            yellow = 220,
            grey = 240,
            needs = 4,
            others = { [4236] = 4, [4304] = 12, [8343] = 2, [249427] = 3, [249428] = 6 },
            forever = true,
        }, -- Mender's Mail Bracers
        {
            spell = 1255050,
            makes = 252543,
            count = 1,
            profession = "leatherworking",
            learn = 225,
            yellow = 245,
            grey = 265,
            needs = 4,
            others = { [4236] = 4, [4304] = 12, [8343] = 2, [249427] = 3, [249428] = 6 },
            forever = true,
        }, -- Mender's Leather Bracers
        {
            spell = 1254994,
            makes = 252579,
            count = 1,
            profession = "leatherworking",
            learn = 235,
            yellow = 255,
            grey = 275,
            needs = 6,
            others = { [4304] = 16, [8172] = 2, [8343] = 2, [249427] = 4, [249428] = 8 },
            forever = true,
        }, -- Mender's Mail Sabatons
        {
            spell = 1255043,
            makes = 252472,
            count = 1,
            profession = "leatherworking",
            learn = 235,
            yellow = 255,
            grey = 275,
            needs = 6,
            others = { [4304] = 16, [8172] = 2, [8343] = 2, [249427] = 4, [249428] = 8 },
            forever = true,
        }, -- Mender's Leather Boots
        {
            spell = 1254982,
            makes = 252591,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 270,
            grey = 290,
            needs = 8,
            others = { [8170] = 12, [8172] = 4, [8343] = 2, [249427] = 5, [249428] = 10 },
            forever = true,
        }, -- Mender's Mail Belt
        {
            spell = 1254986,
            makes = 252587,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 255,
            grey = 255,
            needs = 4,
            others = { [4304] = 16, [8172] = 2 },
            forever = true,
        }, -- Mender's Mail Gauntlets
        {
            spell = 1255031,
            makes = 252477,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 270,
            grey = 290,
            needs = 8,
            others = { [8170] = 12, [8172] = 4, [8343] = 2, [249427] = 5, [249428] = 10 },
            forever = true,
        }, -- Mender's Leather Waistguard
        {
            spell = 1255036,
            makes = 252551,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 255,
            grey = 255,
            needs = 4,
            others = { [4304] = 16, [8172] = 2 },
            forever = true,
        }, -- Mender's Leather Gauntlets
    },
    [5503] = { -- Clam Meat
        {
            spell = 6499,
            makes = 5525,
            count = 1,
            profession = "cooking",
            yellow = 90,
            grey = 130,
            needs = 1,
            others = { [159] = 1 },
        }, -- Boiled Clams
        {
            spell = 6501,
            makes = 5526,
            count = 1,
            profession = "cooking",
            learn = 90,
            yellow = 130,
            grey = 170,
            needs = 1,
            others = { [1179] = 1, [2678] = 1 },
        }, -- Clam Chowder
    },
    [5504] = { -- Tangy Clam Meat
        {
            spell = 6500,
            makes = 5527,
            count = 1,
            profession = "cooking",
            yellow = 165,
            grey = 205,
            needs = 1,
            others = { [2692] = 1 },
        }, -- Goblin Deviled Clams
    },
    [6370] = { -- Blackmouth Oil
        {
            spell = 7179,
            makes = 5996,
            count = 1,
            profession = "alchemy",
            yellow = 120,
            grey = 160,
            needs = 2,
            others = { [3371] = 1, [3820] = 1 },
        }, -- Draught of Water Breathing
        {
            spell = 7841,
            makes = 6372,
            count = 1,
            profession = "alchemy",
            yellow = 130,
            grey = 170,
            needs = 1,
            others = { [2452] = 1, [3371] = 1 },
        }, -- Swim Speed Potion
        {
            spell = 6624,
            makes = 5634,
            count = 1,
            profession = "alchemy",
            learn = 150,
            yellow = 175,
            grey = 215,
            needs = 2,
            others = { [3372] = 1, [3820] = 1 },
        }, -- Free Action Potion
        {
            spell = 11447,
            makes = 8827,
            count = 1,
            profession = "alchemy",
            yellow = 190,
            grey = 230,
            needs = 1,
            others = { [3357] = 1, [3372] = 1 },
        }, -- Draught of Water Walking
    },
    [6371] = { -- Fire Oil
        {
            spell = 1257372,
            makes = 253893,
            count = 1,
            profession = "tailoring",
            learn = 60,
            yellow = 85,
            grey = 120,
            needs = 1,
            others = { [2321] = 2, [2997] = 8, [249409] = 2 },
            forever = true,
        }, -- Flame Boots
        {
            spell = 1257378,
            makes = 253905,
            count = 1,
            profession = "tailoring",
            learn = 75,
            yellow = 80,
            grey = 80,
            needs = 2,
            others = { [2321] = 4, [2997] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Flame Gown
        {
            spell = 1257384,
            makes = 253917,
            count = 1,
            profession = "tailoring",
            learn = 75,
            yellow = 100,
            grey = 135,
            needs = 2,
            others = { [2321] = 4, [2997] = 6, [249409] = 3 },
            forever = true,
        }, -- Flame Gloves
        {
            spell = 1257390,
            makes = 253929,
            count = 1,
            profession = "tailoring",
            learn = 85,
            yellow = 110,
            grey = 145,
            needs = 3,
            others = { [2321] = 4, [4305] = 8, [249409] = 3 },
            forever = true,
        }, -- Flame Sash
        {
            spell = 1257396,
            makes = 253941,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 105,
            grey = 105,
            needs = 4,
            others = { [2321] = 4, [4305] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Flame Leggings
        {
            spell = 1257402,
            makes = 253953,
            count = 1,
            profession = "tailoring",
            learn = 100,
            yellow = 125,
            grey = 160,
            needs = 4,
            others = { [2842] = 1, [4291] = 2, [4305] = 10, [11082] = 2, [249409] = 4 },
            forever = true,
        }, -- Flame Circlet
        {
            spell = 1257408,
            makes = 253965,
            count = 1,
            profession = "tailoring",
            learn = 110,
            yellow = 130,
            grey = 160,
            needs = 6,
            others = { [2842] = 2, [4291] = 2, [4305] = 12, [11082] = 2, [249409] = 6 },
            forever = true,
        }, -- Flame Gown
        {
            spell = 1257415,
            makes = 253979,
            count = 1,
            profession = "tailoring",
            learn = 125,
            yellow = 130,
            grey = 130,
            needs = 6,
            others = { [2321] = 4, [4305] = 8, [249409] = 2 },
            forever = true,
        }, -- Filigreed Flame Circlet
        {
            spell = 1257421,
            makes = 253991,
            count = 1,
            profession = "tailoring",
            learn = 125,
            yellow = 145,
            grey = 175,
            needs = 8,
            others = { [2321] = 3, [2842] = 2, [4305] = 14, [11082] = 3, [249409] = 8 },
            forever = true,
        }, -- Flame Leggings
        {
            spell = 8789,
            makes = 7056,
            count = 1,
            profession = "tailoring",
            learn = 145,
            yellow = 165,
            grey = 195,
            needs = 2,
            others = { [2604] = 2, [4291] = 1, [4305] = 5 },
        }, -- Crimson Silk Cloak
        {
            spell = 8793,
            makes = 7059,
            count = 1,
            profession = "tailoring",
            learn = 155,
            yellow = 175,
            grey = 205,
            needs = 2,
            others = { [2604] = 2, [4291] = 2, [4305] = 5 },
        }, -- Crimson Silk Shoulders
        {
            spell = 7257,
            makes = 6049,
            count = 1,
            profession = "alchemy",
            learn = 165,
            yellow = 210,
            grey = 250,
            needs = 1,
            others = { [3372] = 1, [4402] = 1 },
        }, -- Fire Protection Potion
        {
            spell = 7845,
            makes = 6373,
            count = 1,
            profession = "alchemy",
            yellow = 165,
            grey = 205,
            needs = 2,
            others = { [3356] = 1, [3372] = 1 },
        }, -- Elixir of Fire Power
        {
            spell = 8804,
            makes = 7064,
            count = 1,
            profession = "tailoring",
            yellow = 190,
            grey = 220,
            needs = 2,
            others = { [2604] = 4, [4291] = 2, [4304] = 2, [4305] = 6, [7068] = 2 },
        }, -- Crimson Silk Gloves
        {
            spell = 26277,
            makes = 21546,
            count = 1,
            profession = "alchemy",
            learn = 250,
            yellow = 265,
            grey = 305,
            needs = 3,
            others = { [4625] = 3, [8925] = 1 },
        }, -- Elixir of Holy Power
    },
    [6662] = { -- Elixir of Giant Growth
        {
            spell = 1255095,
            makes = 252453,
            count = 1,
            profession = "leatherworking",
            learn = 135,
            yellow = 155,
            grey = 175,
            needs = 2,
            others = { [4265] = 1, [11083] = 2 },
            forever = true,
        }, -- Forceful Heavy Armor Kit
    },
    [7082] = { -- Essence of Air
        {
            spell = 19067,
            makes = 15057,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 270,
            grey = 290,
            needs = 2,
            others = { [7080] = 2, [8170] = 16, [14341] = 1 },
        }, -- Stormshroud Pants
        {
            spell = 19079,
            makes = 15056,
            count = 1,
            profession = "leatherworking",
            learn = 260,
            yellow = 280,
            grey = 300,
            needs = 3,
            others = { [7080] = 3, [8170] = 16, [14341] = 1, [15407] = 1 },
        }, -- Stormshroud Armor
        {
            spell = 19090,
            makes = 15058,
            count = 1,
            profession = "leatherworking",
            learn = 270,
            yellow = 290,
            grey = 310,
            needs = 3,
            others = { [7080] = 3, [8170] = 12, [12810] = 2, [14341] = 1 },
        }, -- Stormshroud Shoulders
        {
            spell = 17559,
            makes = 7078,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 275,
            grey = 290,
            needs = 1,
        }, -- Essence of Fire
        {
            spell = 17632,
            makes = 13503,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 315,
            grey = 330,
            needs = 8,
            others = { [7076] = 8, [7078] = 8, [7080] = 8, [9262] = 2, [12803] = 8, [13468] = 4 },
        }, -- Alchemist's Stone
        {
            spell = 1297120,
            makes = 275604,
            count = 1,
            profession = "tailoring",
            learn = 285,
            yellow = 290,
            grey = 295,
            needs = 3,
            others = { [14048] = 4, [14341] = 6, [14343] = 1 },
            forever = true,
        }, -- Venomspew Gloves
        {
            spell = 1297126,
            makes = 275610,
            count = 1,
            profession = "leatherworking",
            learn = 285,
            yellow = 290,
            grey = 295,
            needs = 3,
            others = { [8170] = 12, [12810] = 3, [14341] = 6 },
            forever = true,
        }, -- Bileblister Claws
        {
            spell = 22922,
            makes = 18506,
            count = 1,
            profession = "leatherworking",
            learn = 290,
            yellow = 310,
            grey = 330,
            needs = 6,
            others = { [8170] = 12, [11754] = 4, [14341] = 4, [15407] = 2 },
        }, -- Mongoose Boots
        {
            spell = 26279,
            makes = 21278,
            count = 1,
            profession = "leatherworking",
            learn = 290,
            yellow = 310,
            grey = 330,
            needs = 4,
            others = { [7080] = 4, [12810] = 6, [14227] = 2, [15407] = 2 },
        }, -- Stormshroud Gloves
        {
            spell = 1297121,
            makes = 275605,
            count = 1,
            profession = "tailoring",
            learn = 290,
            yellow = 295,
            grey = 300,
            needs = 3,
            others = { [14048] = 6, [14341] = 6, [14343] = 1 },
            forever = true,
        }, -- Venomspew Cord
        {
            spell = 1297127,
            makes = 275611,
            count = 1,
            profession = "leatherworking",
            learn = 290,
            yellow = 295,
            grey = 300,
            needs = 3,
            others = { [8170] = 18, [12810] = 3, [14341] = 6 },
            forever = true,
        }, -- Bileblister Girdle
        {
            spell = 18457,
            makes = 14152,
            count = 1,
            profession = "tailoring",
            learn = 295,
            yellow = 310,
            grey = 340,
            needs = 8,
            others = {
                [7076] = 8,
                [7078] = 8,
                [7080] = 8,
                [14048] = 12,
                [14341] = 2,
                [249431] = 10,
            },
        }, -- Robe of the Archmage
        {
            spell = 1297122,
            makes = 275606,
            count = 1,
            profession = "tailoring",
            learn = 295,
            yellow = 295,
            grey = 300,
            needs = 3,
            others = { [14048] = 5, [14341] = 6, [14343] = 1 },
            forever = true,
        }, -- Venomspew Footpads
        {
            spell = 1297128,
            makes = 275612,
            count = 1,
            profession = "leatherworking",
            learn = 295,
            yellow = 295,
            grey = 300,
            needs = 3,
            others = { [8170] = 15, [12810] = 3, [14341] = 6 },
            forever = true,
        }, -- Bileblister Boots
        {
            spell = 22928,
            makes = 18511,
            count = 1,
            profession = "leatherworking",
            learn = 300,
            yellow = 320,
            grey = 340,
            needs = 12,
            others = { [8170] = 30, [12753] = 4, [12809] = 8, [14341] = 8, [15407] = 4 },
        }, -- Shifting Cloak
    },
    [7971] = { -- Black Pearl
        {
            spell = 1257429,
            makes = 254007,
            count = 1,
            profession = "tailoring",
            learn = 140,
            yellow = 145,
            grey = 145,
            needs = 2,
            others = { [4339] = 8, [8343] = 4, [249409] = 2, [249430] = 2 },
            forever = true,
        }, -- Black Slippers
        {
            spell = 1257439,
            makes = 254027,
            count = 1,
            profession = "tailoring",
            learn = 165,
            yellow = 185,
            grey = 215,
            needs = 4,
            others = { [4339] = 12, [8343] = 4, [249409] = 1, [249430] = 2 },
            forever = true,
        }, -- Black Handwraps
        {
            spell = 22711,
            makes = 18238,
            count = 1,
            profession = "leatherworking",
            learn = 175,
            yellow = 185,
            grey = 205,
            needs = 2,
            others = { [1210] = 4, [4236] = 2, [4304] = 6, [7428] = 8, [8343] = 1 },
        }, -- Shadowskin Gloves
        {
            spell = 1257447,
            makes = 254043,
            count = 1,
            profession = "tailoring",
            learn = 190,
            yellow = 195,
            grey = 195,
            needs = 12,
            others = { [4339] = 28, [8343] = 4, [249409] = 4, [249430] = 6 },
            forever = true,
        }, -- Black Cord
        {
            spell = 1257453,
            makes = 254055,
            count = 1,
            profession = "tailoring",
            learn = 195,
            yellow = 210,
            grey = 240,
            needs = 8,
            others = { [4339] = 16, [8343] = 3, [11175] = 2, [249409] = 3, [249430] = 4 },
            forever = true,
        }, -- Netherpearl Shoulders
        {
            spell = 1257459,
            makes = 254067,
            count = 1,
            profession = "tailoring",
            learn = 205,
            yellow = 220,
            grey = 250,
            needs = 10,
            others = { [4339] = 18, [8343] = 3, [11175] = 4, [249409] = 4, [249430] = 6 },
            forever = true,
        }, -- Netherpearl Cuffs
        {
            spell = 1257469,
            makes = 254087,
            count = 1,
            profession = "tailoring",
            learn = 215,
            yellow = 230,
            grey = 260,
            needs = 12,
            others = { [8343] = 4, [14048] = 8, [249409] = 5, [249430] = 8 },
            forever = true,
        }, -- Black Waistcord
        {
            spell = 13702,
            makes = 11145,
            count = 1,
            profession = "enchanting",
            yellow = 220,
            grey = 260,
            needs = 1,
            others = { [11135] = 1, [11137] = 1, [11144] = 1 },
        }, -- Runed Truesilver Rod
        {
            spell = 1257476,
            makes = 254101,
            count = 1,
            profession = "tailoring",
            learn = 235,
            yellow = 240,
            grey = 240,
            needs = 4,
            others = { [8343] = 4, [14048] = 8, [249409] = 4, [249430] = 4 },
            forever = true,
        }, -- Black Gloves
        {
            spell = 1257482,
            makes = 254113,
            count = 1,
            profession = "tailoring",
            learn = 235,
            yellow = 250,
            grey = 280,
            needs = 14,
            others = { [8343] = 4, [14048] = 10, [249409] = 6, [249427] = 4, [249430] = 10 },
            forever = true,
        }, -- Black Sandals
        {
            spell = 10647,
            makes = 8349,
            count = 1,
            profession = "leatherworking",
            yellow = 245,
            grey = 265,
            needs = 2,
            others = { [4304] = 40, [8168] = 40, [8172] = 4, [8343] = 4 },
        }, -- Feathered Breastplate
        {
            spell = 19065,
            makes = 15092,
            count = 1,
            profession = "leatherworking",
            learn = 250,
            yellow = 270,
            grey = 290,
            needs = 1,
            others = { [8170] = 6, [14047] = 6, [14341] = 1 },
        }, -- Runic Leather Bracers
        {
            spell = 19435,
            makes = 15802,
            count = 1,
            profession = "tailoring",
            yellow = 285,
            grey = 315,
            needs = 2,
            others = { [14048] = 6, [14341] = 1, [14342] = 4 },
        }, -- Mooncloth Boots
    },
    [7974] = { -- Zesty Clam Meat
        {
            spell = 20626,
            makes = 16766,
            count = 2,
            profession = "cooking",
            learn = 225,
            yellow = 265,
            grey = 305,
            needs = 2,
            others = { [1179] = 1, [2692] = 1 },
        }, -- Undermine Clam Chowder
        {
            spell = 1250158,
            makes = 250081,
            count = 1,
            profession = "cooking",
            learn = 275,
            yellow = 280,
            grey = 310,
            needs = 3,
            others = { [3713] = 4 },
            forever = true,
        }, -- Clam Linguine
    },
    [12808] = { -- Essence of Undeath
        {
            spell = 18436,
            makes = 14136,
            count = 1,
            profession = "tailoring",
            learn = 245,
            yellow = 260,
            grey = 290,
            needs = 4,
            others = { [7080] = 4, [14048] = 10, [14256] = 12, [14341] = 1 },
        }, -- Robe of Winter Night
        {
            spell = 1249107,
            makes = 249469,
            count = 1,
            profession = "enchanting",
            learn = 265,
            yellow = 285,
            grey = 325,
            needs = 1,
            others = { [11382] = 1, [14343] = 3 },
            forever = true,
        }, -- Frozen Heart of the Mountain
        {
            spell = 17563,
            makes = 7080,
            count = 1,
            profession = "alchemy",
            learn = 275,
            yellow = 275,
            grey = 290,
            needs = 1,
        }, -- Essence of Water
        {
            spell = 22867,
            makes = 18407,
            count = 1,
            profession = "tailoring",
            learn = 280,
            yellow = 295,
            grey = 325,
            needs = 8,
            others = { [12662] = 6, [14048] = 12, [14256] = 20, [14341] = 2 },
        }, -- Felcloth Gloves
        {
            spell = 1227724,
            makes = 239148,
            count = 1,
            profession = "tailoring",
            learn = 290,
            yellow = 300,
            grey = 305,
            needs = 2,
            others = { [2604] = 4, [12811] = 2, [12938] = 1, [14048] = 24 },
            forever = true,
        }, -- Crimson Dawnwoven Bag
        {
            spell = 18458,
            makes = 14153,
            count = 1,
            profession = "tailoring",
            learn = 295,
            yellow = 310,
            grey = 340,
            needs = 8,
            others = {
                [7078] = 8,
                [12662] = 20,
                [14048] = 12,
                [14256] = 40,
                [14341] = 2,
                [249431] = 10,
            },
        }, -- Robe of the Void
    },
    [13423] = { -- Stonescale Oil
        {
            spell = 1255030,
            makes = 252552,
            count = 1,
            profession = "leatherworking",
            learn = 255,
            yellow = 275,
            grey = 295,
            needs = 6,
            others = { [6261] = 3, [8170] = 16, [14341] = 1, [15407] = 2 },
            forever = true,
        }, -- Tooled Leather Armor
        {
            spell = 17554,
            makes = 13445,
            count = 1,
            profession = "alchemy",
            learn = 265,
            yellow = 280,
            grey = 320,
            needs = 2,
            others = { [8838] = 1, [8925] = 1 },
        }, -- Elixir of Greater Defense
        {
            spell = 17570,
            makes = 13455,
            count = 1,
            profession = "alchemy",
            learn = 280,
            yellow = 295,
            grey = 335,
            needs = 3,
            others = { [8925] = 1, [10620] = 1 },
        }, -- Greater Stoneshield Potion
        {
            spell = 17634,
            makes = 13506,
            count = 1,
            profession = "alchemy",
            learn = 300,
            yellow = 315,
            grey = 330,
            needs = 30,
            others = { [8925] = 1, [13465] = 10, [13468] = 1 },
        }, -- Flask of Petrification
        {
            spell = 17635,
            makes = 13510,
            count = 1,
            profession = "alchemy",
            learn = 300,
            yellow = 315,
            grey = 330,
            needs = 10,
            others = { [8846] = 30, [8925] = 1, [13468] = 1 },
        }, -- Flask of the Titans
    },
    [13926] = { -- Golden Pearl
        {
            spell = 1257430,
            makes = 254009,
            count = 1,
            profession = "tailoring",
            learn = 140,
            yellow = 145,
            grey = 145,
            needs = 2,
            others = { [4339] = 8, [8343] = 4, [249409] = 2, [249430] = 2 },
            forever = true,
        }, -- Golden Slippers
        {
            spell = 1257440,
            makes = 254029,
            count = 1,
            profession = "tailoring",
            learn = 165,
            yellow = 185,
            grey = 215,
            needs = 4,
            others = { [4339] = 12, [8343] = 4, [249409] = 1, [249430] = 2 },
            forever = true,
        }, -- Golden Handwraps
        {
            spell = 1257448,
            makes = 254045,
            count = 1,
            profession = "tailoring",
            learn = 190,
            yellow = 195,
            grey = 195,
            needs = 12,
            others = { [4339] = 28, [8343] = 4, [249409] = 4, [249430] = 6 },
            forever = true,
        }, -- Golden Cord
        {
            spell = 1257454,
            makes = 254057,
            count = 1,
            profession = "tailoring",
            learn = 195,
            yellow = 210,
            grey = 240,
            needs = 8,
            others = { [4339] = 16, [8343] = 3, [11175] = 2, [249409] = 3, [249430] = 4 },
            forever = true,
        }, -- Nethershine Shoulders
        {
            spell = 1257460,
            makes = 254069,
            count = 1,
            profession = "tailoring",
            learn = 205,
            yellow = 220,
            grey = 250,
            needs = 10,
            others = { [4339] = 18, [8343] = 3, [11175] = 4, [249409] = 4, [249430] = 6 },
            forever = true,
        }, -- Nethershine Cuffs
        {
            spell = 1257470,
            makes = 254089,
            count = 1,
            profession = "tailoring",
            learn = 215,
            yellow = 230,
            grey = 260,
            needs = 12,
            others = { [8343] = 4, [14048] = 8, [249409] = 5, [249430] = 8 },
            forever = true,
        }, -- Golden Waistcord
        {
            spell = 1257477,
            makes = 254103,
            count = 1,
            profession = "tailoring",
            learn = 235,
            yellow = 240,
            grey = 240,
            needs = 4,
            others = { [8343] = 4, [14048] = 8, [249409] = 4, [249430] = 4 },
            forever = true,
        }, -- Golden Gloves
        {
            spell = 1257483,
            makes = 254115,
            count = 1,
            profession = "tailoring",
            learn = 235,
            yellow = 250,
            grey = 280,
            needs = 14,
            others = { [8343] = 4, [14048] = 10, [249409] = 6, [249427] = 4, [249430] = 10 },
            forever = true,
        }, -- Golden Sandals
        {
            spell = 23664,
            makes = 19056,
            count = 1,
            profession = "tailoring",
            learn = 255,
            yellow = 270,
            grey = 300,
            needs = 2,
            others = { [12809] = 2, [12810] = 4, [14048] = 6, [14227] = 2 },
        }, -- Argent Boots
        {
            spell = 22902,
            makes = 18486,
            count = 1,
            profession = "tailoring",
            learn = 275,
            yellow = 290,
            grey = 320,
            needs = 2,
            others = { [14048] = 6, [14341] = 2, [14342] = 4 },
        }, -- Mooncloth Robe
        {
            spell = 22869,
            makes = 18409,
            count = 1,
            profession = "tailoring",
            learn = 280,
            yellow = 295,
            grey = 325,
            needs = 2,
            others = { [14048] = 12, [14341] = 2, [14342] = 6 },
        }, -- Mooncloth Gloves
        {
            spell = 20051,
            makes = 16207,
            count = 1,
            profession = "enchanting",
            learn = 290,
            yellow = 310,
            grey = 350,
            needs = 1,
            others = { [14343] = 4, [14344] = 2, [16203] = 4, [16204] = 10, [16206] = 1 },
        }, -- Runed Arcanite Rod
        {
            spell = 18454,
            makes = 14146,
            count = 1,
            profession = "tailoring",
            learn = 295,
            yellow = 310,
            grey = 340,
            needs = 4,
            others = {
                [9210] = 8,
                [12364] = 4,
                [12810] = 6,
                [14048] = 10,
                [14341] = 2,
                [14342] = 8,
                [249431] = 10,
            },
        }, -- Gloves of Spell Mastery
        {
            spell = 18456,
            makes = 14154,
            count = 1,
            profession = "tailoring",
            learn = 295,
            yellow = 310,
            grey = 340,
            needs = 2,
            others = {
                [9210] = 8,
                [12811] = 2,
                [14048] = 12,
                [14341] = 2,
                [14342] = 8,
                [249431] = 10,
            },
        }, -- Truefaith Vestments
    },
}
