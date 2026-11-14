local _, ns = ...

-- How fishing goes from the first cast to Artisan, and what's worth doing
-- on the way: the facts behind the Fishing Book's Next page.
--
-- Kept by hand, from docs/research/fishing-progression-on-forever.md.
-- Ranks and item requirements come from the game's own tables; trainers,
-- waters and events come from public guides and haven't been checked in
-- game, which the page says wherever it shows them.
--
-- Coordinates are as the guides give them: 0 to 100 across the zone's map.
-- Where two guides disagree, the first is used and the other noted.
--
-- Item IDs are all in the client's item table for build 1.60.1.70888. The
-- page reads names and icons from the client, so the names in comments
-- are only labels.

ns.Progression = {}
local Progression = ns.Progression

-- Ranks -----------------------------------------------------------------------

-- Each rank in order: the cap it lifts skill to, and what it takes to
-- learn. skill and level are what the game asks for before it will teach
-- the rank; npc names the one person who teaches it, where it isn't any
-- trainer.
--
--   how   "trainer", "book" or "quest"
--   cost  copper, where the rank is bought
Progression.ranks = {
    {
        name = "Apprentice",
        cap = 75,
        how = "trainer",
        text = "Any fishing trainer will teach you, whatever your level.",
    },
    {
        name = "Journeyman",
        cap = 150,
        how = "trainer",
        skill = 50,
        level = 10,
        text = "Any fishing trainer teaches Journeyman.",
    },
    {
        name = "Expert",
        cap = 225,
        how = "book",
        skill = 125,
        level = 20,
        itemID = 16083, -- Expert Fishing - The Bass and You
        cost = 10000,
        npc = "heming",
        text = "Expert comes from a book that Old Man Heming sells in Booty Bay. It isn't bound,"
            .. " so other players can sell you one too.",
    },
    {
        name = "Artisan",
        cap = 300,
        how = "quest",
        skill = 225,
        level = 35,
        npc = "pagle",
        text = "Nat Pagle in Dustwallow Marsh has a quest for it: four rare fish that only bite"
            .. " while the quest is open.",
    },
}

-- Who to see --------------------------------------------------------------------

-- side is "Alliance", "Horde" or "Both". The first trainer listed for each
-- side stands in when none is on the player's continent.
Progression.trainers = {
    {
        side = "Alliance",
        name = "Arnold Leland",
        place = "Stormwind, Trade District",
        uiMapID = 1453,
        x = 55.0,
        y = 69.6,
    },
    {
        side = "Alliance",
        name = "Grimnur Stonebrand",
        place = "Ironforge, Forlorn Cavern",
        uiMapID = 1455,
        x = 48.4,
        y = 6.4,
    },
    { side = "Alliance", name = "Astaia", place = "Darnassus", uiMapID = 1457, x = 47.6, y = 56.6 },
    {
        side = "Alliance",
        name = "Lee Brown",
        place = "Crystal Lake, by Goldshire",
        uiMapID = 1429,
        x = 47.6,
        y = 62.2,
    },
    {
        side = "Alliance",
        name = "Paxton Ganter",
        place = "Iceflow Lake, Dun Morogh",
        uiMapID = 1426,
        x = 35.6,
        y = 40.4,
    },
    {
        side = "Alliance",
        name = "Androl Oakhand",
        place = "Rut'theran Village",
        uiMapID = 1438,
        x = 55.8,
        y = 93.6,
    },
    {
        side = "Alliance",
        name = "Warg Deepwater",
        place = "Thelsamar, Loch Modan",
        uiMapID = 1432,
        x = 40.6,
        y = 39.6,
    },
    {
        side = "Alliance",
        name = "Harold Riggs",
        place = "Menethil Harbor, Wetlands",
        uiMapID = 1437,
        x = 8.2,
        y = 58.6,
    },
    -- The other guide has 21.4, 51.1.
    {
        side = "Alliance",
        name = "Matthew Hooper",
        place = "Lakeshire, Redridge",
        uiMapID = 1433,
        x = 26.8,
        y = 50.4,
    },
    -- The other guide has 50.4, 64.1.
    {
        side = "Alliance",
        name = "Donald Rabonne",
        place = "Southshore, Hillsbrad",
        uiMapID = 1424,
        x = 50.6,
        y = 61.0,
    },
    {
        side = "Alliance",
        name = "Brannock",
        place = "Feathermoon Stronghold, Feralas",
        uiMapID = 1444,
        x = 32.2,
        y = 41.6,
    },

    {
        side = "Horde",
        name = "Lumak",
        place = "Orgrimmar, Valley of Honor",
        uiMapID = 1454,
        x = 69.8,
        y = 29.6,
    },
    {
        side = "Horde",
        name = "Kah Mistrunner",
        place = "Thunder Bluff",
        uiMapID = 1456,
        x = 56.0,
        y = 46.8,
    },
    {
        side = "Horde",
        name = "Armand Cromwell",
        place = "Undercity, Magic Quarter",
        uiMapID = 1458,
        x = 80.8,
        y = 31.2,
    },
    {
        side = "Horde",
        name = "Clyde Kellen",
        place = "Brightwater Lake, Tirisfal",
        uiMapID = 1420,
        x = 67.2,
        y = 51.0,
    },
    {
        side = "Horde",
        name = "Lau'Tiki",
        place = "Sen'jin Village coast, Durotar",
        uiMapID = 1411,
        x = 53.2,
        y = 81.6,
    },
    -- The other guide has 44.2, 63.7.
    {
        side = "Horde",
        name = "Uthan Stillwater",
        place = "Stonebull Lake, Mulgore",
        uiMapID = 1412,
        x = 44.6,
        y = 60.6,
    },
    {
        side = "Horde",
        name = "Kil'Hiwana",
        place = "Zoram'gar Outpost, Ashenvale",
        uiMapID = 1440,
        x = 10.8,
        y = 33.6,
    },
    {
        side = "Horde",
        name = "Lui'Mala",
        place = "Shadowprey Village, Desolace",
        uiMapID = 1443,
        x = 22.6,
        y = 72.6,
    },
    {
        side = "Horde",
        name = "Katoom the Angler",
        place = "Revantusk Village, Hinterlands",
        uiMapID = 1425,
        x = 80.2,
        y = 81.4,
    },

    {
        side = "Both",
        name = "Myizz Luckycatch",
        place = "Booty Bay",
        uiMapID = 1434,
        x = 27.6,
        y = 77.0,
    },
    {
        side = "Both",
        name = "Krix",
        place = "Powderfuse Port, Riverglades",
        uiMapID = 2548,
        x = 79.2,
        y = 54.8,
    },
    {
        side = "Both",
        name = "Baelann Swiftcurrent",
        place = "Valanaar, Zephras Isle",
        uiMapID = 2521,
        x = 63.2,
        y = 75.8,
    },
    {
        side = "Both",
        name = "Fenn Fairweather",
        place = "Shen'dar Village, Zephras Isle",
        uiMapID = 2521,
        x = 45.0,
        y = 48.4,
    },

    -- Hunter Moore in Hillsbrad (1424, 54.0, 80.2) is Alliance in one guide
    -- and open to both in another, so he's left out until someone looks.
}

-- The two who teach a rank themselves.
Progression.npcs = {
    heming = {
        side = "Both",
        name = "Old Man Heming",
        place = "Booty Bay",
        uiMapID = 1434,
        x = 27.4,
        y = 77.0,
    },
    pagle = {
        side = "Both",
        name = "Nat Pagle",
        place = "his islet, Dustwallow Marsh",
        uiMapID = 1445,
        x = 58.6,
        y = 60.0,
    },
}

-- Where to fish -----------------------------------------------------------------

-- Skill brackets, from..to, with waters for each side and what they
-- mostly give. Zone skill levels are kept on the server, so these are the
-- original game's and only a rough guide. later lists harder waters for
-- the top of the bracket. Forever's own zones (the Riverglades, Mount
-- Hyjal) are left out until there's more than one guide's word for them.
Progression.brackets = {
    {
        from = 1,
        to = 75,
        waters = {
            Alliance = { "Crystal Lake", "Iceflow Lake", "Rut'theran Village" },
            Horde = { "the Durotar coast", "Stonebull Lake", "Brightwater Lake" },
            Both = { "Zephras Isle" },
        },
        note = "City water tends to lose you fish until about 75.",
        catches = {
            6291, -- Raw Brilliant Smallfish
            6303, -- Raw Slitherskin Mackerel
        },
    },
    {
        from = 75,
        to = 150,
        waters = {
            Alliance = { "Westfall", "Darkshore", "Loch Modan" },
            Horde = { "the Barrens", "Silverpine Forest" },
            Both = { "the capital cities' canals" },
        },
        note = "Deviate Fish come from the oases in the Barrens.",
        catches = {
            6289, -- Raw Longjaw Mud Snapper
            6358, -- Oily Blackmouth
            6317, -- Raw Loch Frenzy
            6361, -- Raw Rainbow Fin Albacore
            6522, -- Deviate Fish
        },
    },
    {
        from = 150,
        to = 225,
        waters = {
            Alliance = { "Redridge Mountains", "Duskwood", "the Wetlands" },
            Horde = { "Stonetalon Mountains" },
            Both = { "Hillsbrad Foothills", "Ashenvale" },
        },
        later = {
            "Arathi Highlands",
            "Alterac Mountains",
            "Desolace",
            "Dustwallow Marsh",
            "Stranglethorn Vale",
            "Swamp of Sorrows",
            "Thousand Needles",
        },
        catches = {
            6308, -- Raw Bristle Whisker Catfish
            6359, -- Firefin Snapper
            8365, -- Raw Mithril Head Trout
            6362, -- Raw Rockscale Cod
            21153, -- Raw Greater Sagefish
        },
    },
    {
        from = 225,
        to = 300,
        waters = {
            Both = {
                "Feralas",
                "Tanaris",
                "the Hinterlands",
                "Azshara",
                "Felwood",
                "Moonglade",
                "Un'Goro Crater",
                "Western Plaguelands",
            },
        },
        note = "Nightfin Snapper bite at night, Sunscale Salmon by day.",
        catches = {
            13758, -- Raw Redgill
            4603, -- Raw Spotted Yellowtail
            13759, -- Raw Nightfin Snapper
            13760, -- Raw Sunscale Salmon
            13754, -- Raw Glossy Mightfish
            13422, -- Stonescale Eel
        },
    },
    {
        from = 300,
        waters = {
            Both = { "Winterspring", "Eastern Plaguelands", "Silithus", "Burning Steppes" },
        },
        catches = {
            13888, -- Darkclaw Lobster
            13893, -- Large Raw Mightfish
            13889, -- Raw Whitescale Salmon
        },
    },
}

-- Worth doing ---------------------------------------------------------------------

-- Each entry shows while the player's skill (the rank, not counting lures
-- and gear) is from minSkill to maxSkill, at minLevel or over, and on the
-- right side. A pole drops off once the player has it or a better one; of
-- the lures, only the best one they can use and haven't got is shown.
-- Cooking lines are worked out by the page from Data/Uses.lua.
--
--   kind    "pole", "lure", "quest", "camp" or "event"
--   bonus   a pole's fishing skill (lures take theirs from Data/Lures.lua)
--   title   shown in place of the item's name
--   where   a short place, shown beside the name
--   knownSpell  the entry drops off once the player knows this spell
Progression.worth = {
    {
        -- Shown before Fishing is learned too, since the quest leads to it.
        kind = "quest",
        minSkill = 0,
        maxSkill = 75,
        minLevel = 4,
        itemID = 279967, -- Fish Bowl
        knownSpell = 1229745, -- Fish Bowl, once learned
        title = "Camping 101: Fishing",
        text = "A quest that follows The Great Outdoors: reach skill 20, then a trainer teaches"
            .. " you the Fish Bowl for your campfire.",
    },
    {
        kind = "pole",
        minSkill = 1,
        side = "Alliance",
        itemID = 12225, -- Blump Family Fishing Pole
        bonus = 3,
        where = "Darkshore",
        text = "The reward for the quest The Family and the Fishing Pole. Adds 3 to your skill.",
    },
    {
        kind = "pole",
        minSkill = 10,
        minLevel = 5,
        itemID = 6365, -- Strong Fishing Pole
        bonus = 5,
        text = "Fishing supply vendors sell it. Adds 5 to your skill.",
    },
    {
        kind = "pole",
        minSkill = 100,
        minLevel = 25,
        itemID = 6367, -- Big Iron Fishing Pole
        bonus = 20,
        where = "Desolace",
        text = "Now and then found in the Shellfish Traps along the coast. Adds 20.",
    },
    {
        kind = "pole",
        minSkill = 100,
        side = "Horde",
        -- The quest is in the Hinterlands. Its exact level isn't confirmed;
        -- 40 keeps it from players who couldn't get there yet.
        minLevel = 40,
        itemID = 19022, -- Nat Pagle's Extreme Angler FC-5000
        bonus = 25,
        where = "the Hinterlands",
        text = "Adds 25 to your skill. Katoom the Angler at Revantusk Village gives it for the"
            .. " quest Snapjaws, Mon!",
    },
    {
        kind = "pole",
        minSkill = 300,
        itemID = 19970, -- Arcanite Fishing Pole
        bonus = 35,
        text = "A prize for the first to finish the Extravaganza. Adds 35.",
    },
    {
        kind = "lure",
        minSkill = 1,
        itemID = 6529, -- Shiny Bauble
        text = "25 more skill for ten minutes. Fishing supply vendors sell them.",
    },
    {
        kind = "lure",
        minSkill = 50,
        itemID = 6530, -- Nightcrawlers
        text = "50 more skill for ten minutes. Fishing supply vendors sell them.",
    },
    {
        kind = "lure",
        minSkill = 100,
        itemID = 6532, -- Bright Baubles
        text = "75 more skill for ten minutes. Try fishing supply vendors and the auction house.",
    },
    {
        kind = "lure",
        minSkill = 100,
        itemID = 6533, -- Aquadynamic Fish Attractor
        text = "100 more skill for five minutes. Engineers make them, so look at the auction"
            .. " house.",
    },
    {
        kind = "camp",
        minSkill = 140,
        itemID = 279965, -- Fishing Rack
        knownSpell = 1262990,
        text = "Its blueprint drops from Gelihast in Blackfathom Deeps. By a campfire it brings"
            .. " uncommon fish for an hour.",
    },
    {
        -- The skill's a guess at what Stranglethorn's coast asks for.
        kind = "event",
        minSkill = 150,
        itemID = 19807, -- Speckled Tastyfish
        title = "Stranglethorn Fishing Extravaganza",
        where = "Booty Bay",
        text = "Sundays, 2 to 4 pm server time. Catch Speckled Tastyfish; the first to finish win"
            .. " prizes.",
    },
    {
        kind = "camp",
        minSkill = 300,
        itemID = 279966, -- Fishing Hut
        knownSpell = 1262998,
        text = "Rare fish for an hour by a campfire. Nobody seems sure yet where its blueprint"
            .. " comes from.",
    },
}

-- When the Extravaganza starts: day of the week (1 is Sunday, as the game
-- counts), hour and how long it runs, in minutes. Guides give the time
-- without saying which clock it keeps; the page counts down by the
-- server's, which is our best guess.
Progression.extravaganza = { weekday = 1, hour = 14, minutes = 120 }
