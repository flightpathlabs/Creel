local _, ns = ...

-- Everything that can come up on a fishing line in this era, by item ID.
--
-- Kept by hand. tools/make-creel-data.mjs checks every ID against the
-- client's item table for the current build and warns about any it can't
-- find, so a typo shows up the next time the data is generated.
--
-- kind     what the book files it under:
--            fish       eaten, or cooked first
--            oil        the alchemists' fish, pressed into oils
--            shellfish  lobster and clams
--            container  crates, chests, trunks and bloated fish to open
--            trophy     weighed fish, sold to a vendor or held for show
--            event      the Stranglethorn tournament's fish
--            quest      wanted by a quest and little else
--            junk       vendor rubbish
--            other      anything that fits none of the above
-- time     "day" or "night", for fish that only bite then
-- season   "summer" or "winter", for the two fish that take turns
--
-- Names in the comments are only labels. The addon reads names from the
-- client, so they're always in the player's language.
--
-- Where and how often each one turns up is decided on the server, so the
-- book learns that from the player's own catches rather than from here.

ns.Catches = {
    -- Fish for the pan, roughly in the order a fisher meets them
    [6291] = { kind = "fish" }, -- Raw Brilliant Smallfish
    [6303] = { kind = "fish" }, -- Raw Slitherskin Mackerel
    [6289] = { kind = "fish" }, -- Raw Longjaw Mud Snapper
    [6317] = { kind = "fish" }, -- Raw Loch Frenzy
    [6361] = { kind = "fish" }, -- Raw Rainbow Fin Albacore
    [21071] = { kind = "fish" }, -- Raw Sagefish
    [6522] = { kind = "fish" }, -- Deviate Fish
    [6308] = { kind = "fish" }, -- Raw Bristle Whisker Catfish
    [6362] = { kind = "fish" }, -- Raw Rockscale Cod
    [8365] = { kind = "fish" }, -- Raw Mithril Head Trout
    [21153] = { kind = "fish" }, -- Raw Greater Sagefish
    -- Spinefin Halibut had no recipe in the original game and we're not
    -- sure it could be caught there; Forever gives it one, so it's here.
    [8959] = { kind = "fish" }, -- Raw Spinefin Halibut
    [4603] = { kind = "fish" }, -- Raw Spotted Yellowtail
    [13754] = { kind = "fish" }, -- Raw Glossy Mightfish
    [13758] = { kind = "fish" }, -- Raw Redgill
    [13893] = { kind = "fish" }, -- Large Raw Mightfish
    [13889] = { kind = "fish" }, -- Raw Whitescale Salmon
    -- The game files Plated Armorfish as a quest item (it was for an Argent
    -- Dawn writ), but Forever adds a recipe for it, so it cooks like a fish.
    [13890] = { kind = "fish" }, -- Raw Plated Armorfish

    -- Fish that keep hours. In the original game Nightfin Snapper bit from
    -- six in the evening to six in the morning, server time, and Sunscale
    -- Salmon was its daytime counterpart.
    [13759] = { kind = "fish", time = "night" }, -- Raw Nightfin Snapper
    [13760] = { kind = "fish", time = "day" }, -- Raw Sunscale Salmon

    -- The seasonal pair. In the original game they swapped on fixed dates,
    -- squid from about 23 September and bass from about 20 March. Forever
    -- may keep its own calendar, which only catches will tell us.
    [13756] = { kind = "fish", season = "summer" }, -- Raw Summer Bass
    [13755] = { kind = "fish", season = "winter" }, -- Raw Winter Squid

    -- Fish for alchemists, pressed into oils
    [6358] = { kind = "oil" }, -- Oily Blackmouth
    [6359] = { kind = "oil" }, -- Firefin Snapper
    [13422] = { kind = "oil" }, -- Stonescale Eel

    -- Lobster and clams
    [13888] = { kind = "shellfish" }, -- Darkclaw Lobster
    [7973] = { kind = "shellfish" }, -- Big-mouth Clam
    -- These two mostly come from crabs and murlocs. They're here in case
    -- Forever's waters hand them out too.
    [5523] = { kind = "shellfish" }, -- Small Barnacled Clam
    [5524] = { kind = "shellfish" }, -- Thick-shelled Clam

    -- Venture Company crates, lost overboard, full of engineering parts
    [6351] = { kind = "container" }, -- Dented Crate
    [6352] = { kind = "container" }, -- Waterlogged Crate
    [6357] = { kind = "container" }, -- Sealed Crate
    [13874] = { kind = "container" }, -- Heavy Crate

    -- Chests and trunks with no lock
    [6356] = { kind = "container" }, -- Battered Chest
    [6353] = { kind = "container" }, -- Small Chest
    [6307] = { kind = "container" }, -- Message in a Bottle
    [9276] = { kind = "container" }, -- Pirate's Footlocker
    [20708] = { kind = "container" }, -- Tightly Sealed Trunk
    [21113] = { kind = "container" }, -- Watertight Trunk
    [21150] = { kind = "container" }, -- Iron Bound Trunk
    [21228] = { kind = "container" }, -- Mithril Bound Trunk

    -- Locked chests: a rogue's lockpicking, or a key, or a blacksmith's
    -- skeleton key
    [6354] = { kind = "container" }, -- Small Locked Chest
    [6355] = { kind = "container" }, -- Sturdy Locked Chest
    [13875] = { kind = "container" }, -- Ironbound Locked Chest
    [13918] = { kind = "container" }, -- Reinforced Locked Chest

    -- Bloated fish, which have swallowed something worth cutting out
    [6643] = { kind = "container" }, -- Bloated Brilliant Smallfish
    [6644] = { kind = "container" }, -- Bloated Mackerel
    [6645] = { kind = "container" }, -- Bloated Mud Snapper
    [6646] = { kind = "container" }, -- Bloated Albacore
    [6647] = { kind = "container" }, -- Bloated Bristle Whisker Catfish
    [21162] = { kind = "container" }, -- Bloated Oily Blackmouth
    [21163] = { kind = "container" }, -- Bloated Firefin Snapper
    [21164] = { kind = "container" }, -- Bloated Rockscale Cod
    [8366] = { kind = "container" }, -- Bloated Mithril Head Trout
    [13881] = { kind = "container" }, -- Bloated Redgill
    [21243] = { kind = "container" }, -- Bloated Glossy Mightfish
    [13891] = { kind = "container" }, -- Bloated Whitescale Salmon

    -- Weighed fish. The yellowtail and lobsters are for selling; the rest
    -- can also be held in the off hand.
    [6292] = { kind = "trophy" }, -- 10 Pound Mud Snapper
    [6294] = { kind = "trophy" }, -- 12 Pound Mud Snapper
    [6295] = { kind = "trophy" }, -- 15 Pound Mud Snapper
    [6309] = { kind = "trophy" }, -- 17 Pound Catfish
    [6310] = { kind = "trophy" }, -- 19 Pound Catfish
    [6311] = { kind = "trophy" }, -- 22 Pound Catfish
    [6363] = { kind = "trophy" }, -- 26 Pound Catfish
    [6364] = { kind = "trophy" }, -- 32 Pound Catfish
    [13885] = { kind = "trophy" }, -- 34 Pound Redgill
    [13886] = { kind = "trophy" }, -- 37 Pound Redgill
    [13882] = { kind = "trophy" }, -- 42 Pound Redgill
    [13883] = { kind = "trophy" }, -- 45 Pound Redgill
    [13884] = { kind = "trophy" }, -- 49 Pound Redgill
    [13887] = { kind = "trophy" }, -- 52 Pound Redgill
    [13901] = { kind = "trophy" }, -- 15 Pound Salmon
    [13902] = { kind = "trophy" }, -- 18 Pound Salmon
    [13903] = { kind = "trophy" }, -- 22 Pound Salmon
    [13904] = { kind = "trophy" }, -- 25 Pound Salmon
    [13905] = { kind = "trophy" }, -- 29 Pound Salmon
    [13906] = { kind = "trophy" }, -- 32 Pound Salmon
    [13876] = { kind = "trophy" }, -- 40 Pound Yellowtail
    [13877] = { kind = "trophy" }, -- 47 Pound Yellowtail
    [13878] = { kind = "trophy" }, -- 53 Pound Yellowtail
    [13879] = { kind = "trophy" }, -- 59 Pound Yellowtail
    [13880] = { kind = "trophy" }, -- 68 Pound Yellowtail
    [13907] = { kind = "trophy" }, -- 7 Pound Lobster
    [13908] = { kind = "trophy" }, -- 9 Pound Lobster
    [13909] = { kind = "trophy" }, -- 12 Pound Lobster
    [13910] = { kind = "trophy" }, -- 15 Pound Lobster
    [13911] = { kind = "trophy" }, -- 19 Pound Lobster
    [13912] = { kind = "trophy" }, -- 21 Pound Lobster
    [13913] = { kind = "trophy" }, -- 22 Pound Lobster
    [13914] = { kind = "trophy" }, -- 70 Pound Mightfish
    [13915] = { kind = "trophy" }, -- 85 Pound Mightfish
    [13916] = { kind = "trophy" }, -- 92 Pound Mightfish
    [13917] = { kind = "trophy" }, -- 103 Pound Mightfish

    -- The Stranglethorn Fishing Extravaganza, caught only while it runs
    [19807] = { kind = "event" }, -- Speckled Tastyfish
    [19803] = { kind = "event" }, -- Brownell's Blue Striped Racer
    [19805] = { kind = "event" }, -- Keefer's Angelfish
    [19806] = { kind = "event" }, -- Dezian Queenfish

    -- Quest fish: Nat Pagle's four, Zul'Gurub's, and a few for earlier quests
    [16967] = { kind = "quest" }, -- Feralas Ahi
    [16968] = { kind = "quest" }, -- Sar'theris Striker
    [16969] = { kind = "quest" }, -- Savage Coast Blue Sailfin
    [16970] = { kind = "quest" }, -- Misty Reed Mahi Mahi
    [19975] = { kind = "quest" }, -- Zulian Mudskunk
    [1467] = { kind = "quest" }, -- Spotted Sunfish
    [6717] = { kind = "quest" }, -- Gaffer Jack
    [6718] = { kind = "quest" }, -- Electropeller
    [12238] = { kind = "quest" }, -- Darkshore Grouper

    -- Junk, though the two fish can be eaten at a pinch
    [6458] = { kind = "junk" }, -- Oil Covered Fish
    [6299] = { kind = "junk" }, -- Sickly Looking Fish
    [17057] = { kind = "junk" }, -- Shiny Fish Scales
    [17058] = { kind = "junk" }, -- Fish Oil

    -- Everything else: water from the elemental pools, and the eel only the
    -- Argent Dawn wanted
    [7070] = { kind = "other" }, -- Elemental Water
    [7079] = { kind = "other" }, -- Globe of Water
    [7080] = { kind = "other" }, -- Essence of Water
    [13757] = { kind = "other" }, -- Lightning Eel
}
