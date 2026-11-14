local _, ns = ...

-- Hand-written facts about the catches that have a story, by item ID.
-- One is picked at random when the fish is caught or looked at in the book.
--
-- Our own words, checked against the original game. Recipes, skill levels
-- and prices are worked out at run time from Data/Uses.lua and the client,
-- so they don't belong here. Anything we weren't sure of is left in a
-- comment instead.
--
-- Adding one: a sentence or two, a fact rather than a joke, and true for
-- this era of the game.

local BLOATED = "Bloated fish have swallowed something on the way up. Open it for a gem, or now and"
    .. " then a ring."
local VENTURE = "Venture Company cargo that went over the side. Expect engineering odds and ends:"
    .. " blasting powder, tubes, the occasional part."
local HELD = "Weighed fish do nothing in a fight, but they can be held in the off hand, which is"
    .. " the point."
local TAGGED = "One of three tagged fish that only turn up during the Stranglethorn Fishing"
    .. " Extravaganza. Someone in Booty Bay will swap it for a piece of fishing gear."
local SPOILS = "It goes off four hours after it's caught, so there's no saving them for next time."
local PAGLE = "Nat Pagle, who keeps a camp in Dustwallow Marsh, asks for four fish, each named"
    .. " after the place it lives."

ns.Tips = {
    [6291] = { -- Raw Brilliant Smallfish
        "For most people, the first fish ever caught.",
        "Forever adds a Fish Bowl to keep one in, made with the Fishing skill rather than"
            .. " Cooking.",
    },

    -- Eating a raw Deviate Fish also had random effects in the original
    -- game (shrinking, growing, sleeping and so on), but we haven't found
    -- a source we trust for the full list.
    [6522] = { -- Deviate Fish
        "Comes from the oases of the Barrens and the water in Wailing Caverns, where the"
            .. " druids' dream went wrong.",
        "Cooked into Savory Deviate Delight, it turns whoever eats it into a pirate or a"
            .. " ninja for an hour. Nobody can say which beforehand.",
    },

    [21071] = { -- Raw Sagefish
        "Caught from sagefish schools rather than open water. The smoked dish gives mana back"
            .. " over time, which casters like.",
    },
    [21153] = { -- Raw Greater Sagefish
        "The bigger cousin, from greater sagefish schools. Sagefish Delight made from it is a"
            .. " caster's food: mana back over time.",
    },

    [8365] = { -- Raw Mithril Head Trout
        "Forever lets fishers build a Fishing Rack for their campsite, and two of these trout"
            .. " go into it.",
    },

    [13759] = { -- Raw Nightfin Snapper
        "In the original game it only bit in the evening and through the night, by the"
            .. " server's clock. Forever may keep different hours.",
        "Nightfin Soup made from it helps mana come back, so healers tend to want it.",
    },
    [13760] = { -- Raw Sunscale Salmon
        "In the original game this was the day shift: it bit while the sun was up, when the"
            .. " Nightfin Snapper wouldn't.",
    },

    -- The swap dates are the original game's. Forever may run its own
    -- calendar; the book will see it in the catches if so.
    [13756] = { -- Raw Summer Bass
        "A seasonal fish. In the original game it came up from about late March until late"
            .. " September, then gave way to the Winter Squid.",
    },
    [13755] = { -- Raw Winter Squid
        "In the original game it arrived in about late September and stayed until March,"
            .. " taking the Summer Bass's place.",
        "Grilled Squid made from it adds Agility, which is why rogues and hunters keep an eye on"
            .. " the calendar.",
    },

    [13893] = { -- Large Raw Mightfish
        "Mightfish Steak, made from it, is a Stamina food.",
    },
    [13889] = { -- Raw Whitescale Salmon
        "Baked Salmon, made from it, was one of the dishes an Argent Dawn craftsman's writ asked"
            .. " for in the Naxxramas days.",
    },
    [13890] = { -- Raw Plated Armorfish
        "The original game had no recipe for it; the Argent Dawn wanted it for a craftsman's"
            .. " writ. Forever lets you cook it.",
    },

    [6358] = { -- Oily Blackmouth
        "Nobody cooks it. Alchemists press two into a Blackmouth Oil, which goes into potions"
            .. " for swimming, breathing and walking on water, and Free Action Potions.",
    },
    [6359] = { -- Firefin Snapper
        "An alchemist's fish, pressed two at a time into Fire Oil. That ends up in Elixirs of"
            .. " Fire Power, Fire Protection Potions and crimson silk tailoring.",
    },
    [13422] = { -- Stonescale Eel
        "Pressed into Stonescale Oil. A single Flask of the Titans takes ten oils, which is why"
            .. " raiding alchemists buy eels in bulk.",
        "In the Naxxramas days the Argent Dawn wanted these too, through a craftsman's writ.",
    },
    [13757] = { -- Lightning Eel
        "No recipe uses it. Its one buyer in the original game was the Argent Dawn, through a"
            .. " craftsman's writ.",
    },

    [13888] = { -- Darkclaw Lobster
        "A deep saltwater catch, best known from Azshara's Bay of Storms.",
    },

    -- We think the Small Barnacled Clam holds Clam Meat and sometimes a
    -- Small Lustrous Pearl, and the Thick-shelled Clam Tangy Clam Meat and
    -- sometimes an Iridescent Pearl, but haven't confirmed either.
    [7973] = { -- Big-mouth Clam
        "Open it for Zesty Clam Meat, and now and then a Black Pearl or, rarer still, a Golden"
            .. " Pearl.",
    },

    [6351] = { VENTURE }, -- Dented Crate
    [6352] = { VENTURE }, -- Waterlogged Crate
    [6357] = { VENTURE }, -- Sealed Crate
    [13874] = { VENTURE }, -- Heavy Crate

    -- The Lockpicking values are from the game's Lock table for this build.
    [6354] = { -- Small Locked Chest
        "Locked, but only just: any rogue with Lockpicking can open it, and so can a"
            .. " blacksmith's skeleton key.",
    },
    [6355] = { -- Sturdy Locked Chest
        "Needs Lockpicking 70, or a blacksmith's skeleton key. Worth finding a rogue for.",
    },
    [13875] = { -- Ironbound Locked Chest
        "Needs Lockpicking 175, or a blacksmith's skeleton key good enough for it.",
    },
    [13918] = { -- Reinforced Locked Chest
        "The toughest of the fishing chests: Lockpicking 250, or one of the better skeleton"
            .. " keys.",
    },

    [6643] = { BLOATED }, -- Bloated Brilliant Smallfish
    [6645] = { BLOATED }, -- Bloated Mud Snapper
    [6647] = { BLOATED }, -- Bloated Bristle Whisker Catfish
    [8366] = { BLOATED }, -- Bloated Mithril Head Trout
    [13881] = { BLOATED }, -- Bloated Redgill
    [13891] = { BLOATED }, -- Bloated Whitescale Salmon

    [6295] = { HELD }, -- 15 Pound Mud Snapper
    [6364] = { HELD }, -- 32 Pound Catfish
    [13887] = { HELD }, -- 52 Pound Redgill
    [13906] = { HELD }, -- 32 Pound Salmon
    [13917] = { -- 103 Pound Mightfish
        HELD,
        "The heaviest of the weighed fish this era has to offer.",
    },

    -- How many Tastyfish Forever asks for isn't confirmed, so no number.
    [19807] = { -- Speckled Tastyfish
        "Only bites during the Stranglethorn Fishing Extravaganza. The first fishers to hand"
            .. " in their catch in Booty Bay win prizes.",
        "On Forever the first fifty to finish are said to get an Arcanite Fishing Pole and an"
            .. " Extravagant Extravaganza Coin.",
        SPOILS,
    },
    [19803] = { TAGGED, SPOILS }, -- Brownell's Blue Striped Racer
    [19805] = { TAGGED, SPOILS }, -- Keefer's Angelfish
    [19806] = { TAGGED, SPOILS }, -- Dezian Queenfish

    [16967] = { -- Feralas Ahi
        PAGLE,
        "This one lives off Feralas.",
    },
    [16968] = { -- Sar'theris Striker
        PAGLE,
        "This one lives off the Sar'theris Strand in Desolace.",
    },
    [16969] = { -- Savage Coast Blue Sailfin
        PAGLE,
        "This one lives along the Savage Coast of Stranglethorn.",
    },
    [16970] = { -- Misty Reed Mahi Mahi
        PAGLE,
        "This one lives by the Misty Reed Strand in the Swamp of Sorrows.",
    },
    [19975] = { -- Zulian Mudskunk
        "Caught only inside Zul'Gurub. Made into a Mudskunk Lure, it's how a raid calls up"
            .. " Gahz'ranka at Pagle's Pointe.",
    },

    [6458] = { -- Oil Covered Fish
        "Technically food. It heals a little, if you're desperate.",
    },
    [6299] = { -- Sickly Looking Fish
        "Edible, as the game sees it, and about as filling as it looks.",
    },

    [7070] = { -- Elemental Water
        "It comes from the pools called Patches of Elemental Water, like those in Azshara's Bay"
            .. " of Storms, not from ordinary water.",
    },
    [7080] = { -- Essence of Water
        "A rarer find from the same elemental pools that give Elemental Water.",
    },
}
