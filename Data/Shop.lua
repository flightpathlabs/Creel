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
