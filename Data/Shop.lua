local _, ns = ...

-- What vendors charge for the reagents the recipes in Uses.lua call for,
-- where vendors sell them, in copper. The list price before any
-- reputation discount. Used to work out what something costs to make.
--
-- Written by tools/make-creel-data.mjs from ItemSparse for build 1.60.1.70888.
-- Which reagents are listed is decided in the script (vendors' stock is
-- kept on the server). Don't edit this by hand.

ns.ShopPrices = {
    [159] = 25, -- Refreshing Spring Water
    [1179] = 125, -- Ice Cold Milk
    [2320] = 10, -- Coarse Thread
    [2321] = 100, -- Fine Thread
    [2604] = 50, -- Red Dye
    [2678] = 10, -- Mild Spices
    [2692] = 40, -- Hot Spices
    [3371] = 20, -- Empty Vial
    [3372] = 200, -- Leaded Vial
    [3713] = 160, -- Soothing Spices
    [4291] = 500, -- Silken Thread
    [8343] = 2000, -- Heavy Silken Thread
    [8925] = 2500, -- Crystal Vial
    [14341] = 5000, -- Rune Thread
}

-- Cooking recipe spell -> the recipe item that teaches it, and that
-- item's list price in copper.
ns.RecipeItems = {
    [6501] = { item = 5528, price = 800 }, -- Recipe: Clam Chowder
    [7751] = { item = 6325, price = 40 }, -- Recipe: Brilliant Smallfish
    [7752] = { item = 6326, price = 40 }, -- Recipe: Slitherskin Mackerel
    [7753] = { item = 6328, price = 400 }, -- Recipe: Longjaw Mud Snapper
    [7754] = { item = 6329, price = 400 }, -- Recipe: Loch Frenzy Delight
    [7755] = { item = 6330, price = 1200 }, -- Recipe: Bristle Whisker Catfish
    [7827] = { item = 6368, price = 400 }, -- Recipe: Rainbow Fin Albacore
    [7828] = { item = 6369, price = 2200 }, -- Recipe: Rockscale Cod
    [8238] = { item = 6661, price = 460 }, -- Recipe: Savory Deviate Delight
    [18238] = { item = 13939, price = 16000 }, -- Recipe: Spotted Yellowtail
    [18239] = { item = 13940, price = 16000 }, -- Recipe: Cooked Glossy Mightfish
    [18240] = { item = 13942, price = 16000 }, -- Recipe: Grilled Squid
    [18241] = { item = 13941, price = 16000 }, -- Recipe: Filet of Redgill
    [18242] = { item = 13943, price = 16000 }, -- Recipe: Hot Smoked Bass
    [18243] = { item = 13945, price = 20000 }, -- Recipe: Nightfin Soup
    [18244] = { item = 13946, price = 20000 }, -- Recipe: Poached Sunscale Salmon
    [18245] = { item = 13947, price = 20000 }, -- Recipe: Lobster Stew
    [18246] = { item = 13948, price = 20000 }, -- Recipe: Mightfish Steak
    [18247] = { item = 13949, price = 20000 }, -- Recipe: Baked Salmon
    [20626] = { item = 16767, price = 3000 }, -- Recipe: Undermine Clam Chowder
    [20916] = { item = 17062, price = 2200 }, -- Recipe: Mithril Head Trout
    [25704] = { item = 21099, price = 500 }, -- Recipe: Smoked Sagefish
    [25954] = { item = 21219, price = 5000 }, -- Recipe: Sagefish Delight
    [470359] = { item = 232437, price = 20000 }, -- Recipe: Darkclaw Bisque
    [470370] = { item = 232443, price = 16000 }, -- Recipe: Smoked Redgill
    [1225762] = { item = 238649, price = 7500 }, -- Recipe: Specklefin Feast
    [1225763] = { item = 238650, price = 7500 }, -- Recipe: Grand Lobster Banquet
    [1250158] = { item = 250189, price = 0 }, -- Recipe: Clam Linguine
    [1319313] = { item = 286153, price = 0 }, -- Recipe: Plated Armorfish
}
