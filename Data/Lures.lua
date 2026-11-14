local _, ns = ...

-- The lures that go on the pole, by item ID.
--
--   bonus  fishing skill added while the lure lasts
--   skill  fishing skill needed to use it (1 where the item asks for none)
--
-- Kept by hand. tools/make-creel-data.mjs checks both numbers against the
-- client's tables for the current build: the skill from the item, the
-- bonus by following the item's spell to the temporary enchant it puts on
-- the pole and the skill aura that enchant grants.
--
-- Left out on purpose: hats, trinkets and bobber toys, which aren't put on
-- the pole from the bags. Forever's Wide-Brimmed Fishing Hat (259846) does
-- cast a +25 lure onto the pole when used, but it's worn, so it isn't
-- something the lure slot can offer.

ns.Lures = {
    [6529] = { bonus = 25, skill = 1 }, -- Shiny Bauble
    -- Forever's own. It casts the same spell as a Shiny Bauble.
    [268880] = { bonus = 25, skill = 1 }, -- "Secret" Bait
    [6530] = { bonus = 50, skill = 50 }, -- Nightcrawlers
    [6811] = { bonus = 50, skill = 50 }, -- Aquadynamic Fish Lens
    [6532] = { bonus = 75, skill = 100 }, -- Bright Baubles
    [7307] = { bonus = 75, skill = 100 }, -- Flesh Eating Worm
    -- Lasts five minutes where the others last ten.
    [6533] = { bonus = 100, skill = 100 }, -- Aquadynamic Fish Attractor
}
