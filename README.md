# Creel

> **Not released yet.** Creel is still being built and tested on the `dev`
> branch, and isn't on CurseForge or Wago.

A fishing log and one-key cast for World of Warcraft: Forever.

A creel is the wicker basket an angler carries the catch home in. This one
keeps a small, calm panel on screen while you fish, and a book of
everything you've ever caught and where.

## What it does

- **One key to cast and reel.** Press your key to cast, and press it again
  when the bobber splashes to reel in. Or double right-click to cast, if
  you prefer. Setup asks which, and binds nothing until you say so.
- **A panel while you fish.** Time this trip and in all, your skill, a line
  timer, and whether fish get away at this spot at your skill. Each catch
  drops into a card with its quality, what a vendor pays, what it fetches
  at auction, and a tip worth reading. Below it, the trip's tally and what
  it's worth.
- **Quiet while fishing.** One click on the speaker turns off music,
  ambience and chatter so the splash stands out, and gives your own sound
  settings back exactly when you stop.
- **A lure slot.** Shows the lure on your pole and the minutes left. Click
  it to put on the best lure in your bags. It never does it by itself.
- **The Fishing Book.** A gallery of every fish, with silhouettes for the
  ones you haven't caught yet; click one to see what it turns into and
  what that's worth. Your fishing spots, grouped into places so a pond is
  one place and not forty points. Your past trips and records. And what
  fishing has earned you, at the vendor and at auction.

Type `/creel` to show or hide the panel, `/creel book` for the book,
`/creel setup` to run setup again, and `/creel options` for the settings
(also under Options > AddOns > Creel).

## Fair play

Every cast and every reel is your own key press or click. Creel only
decides what your chosen key does while a fishing pole is in your hand,
and hands the key straight back the moment combat starts. It never touches
your saved key bindings, and nothing runs on a timer.

## Works with

- **Goldwise**, for auction prices: Creel asks it for what a catch
  fetches, the same price Goldwise shows. Without it, Creel asks
  Auctionator.
- **Other fishing addons**: if another one also casts on a key, setup says
  so. Let only one of them handle casting.

## Notes

Creel never posts to chat, never shares anything, and never scans the
auction house itself. Prices of things cooked from your fish count toward
earnings too, though Creel can't tell a dish you made from one you bought.

## Licence

MIT. See [LICENSE](LICENSE).

AI tooling is used openly in making this addon alongside hand-written
code; everything is reviewed and tested in game before release.
