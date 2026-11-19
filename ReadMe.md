# eSaith Bag Filter

Sell the loot you picked up by **zone** and **quality**, protect the things you want to keep, and keep track of every character's **lockouts**, **keystone** and **Great Vault**.

Updated for **World of Warcraft: Midnight** (12.1.x). See [CHANGELOG.md](CHANGELOG.md) for what's new.

## Features

**Loot tab**
- Everything you loot is remembered along with the zone (or dungeon/raid) it came from. The window opens to the zone you're in.
- Pick a zone from the dropdown, search by name, and toggle qualities on the left.
- **Click** an item to keep it. Kept items are faded, show a lock, and are never sold.
- **Right-click** an item to hide it from the list for good. Hidden items are never sold either.
- Shift-click to link an item, Ctrl-click to preview it.
- At a vendor, press **Sell Items** to sell everything shown that isn't faded. Big sales ask first, and **Undo Last Sale** buys it all back.
- **Recent Runs** shows what each dungeon, raid or delve run earned.
- Always protected: anything you've equipped and anything in an equipment set.

**Lockouts tab**
- This week: each character's Mythic+ keystone, Great Vault progress, and a reminder when vault rewards are waiting.
- Currencies: whatever each character tracks on their backpack.
- Raids & dungeons: time left on every save, per character.
- Choose which characters and instances to show. Hover a name to see when you last played them; right-click to hide or remove them.

**Settings tab**
- **Selling:** auto-sell junk, confirm big sales, auto-repair (guild funds first), open with vendor.
- **Keep Rules:** green/blue/epic BoE items, gear at your item level, trade goods, and items worth more on the Auction House (needs TradeSkillMaster or Auctionator).
- **Looting & Quests:** quick loot, auto-greed green items, remember loot after logout, quest helper (hold Shift to skip it).
- **Interface:** window size, minimap button, coins on sellable items in your bags (Blizzard bags and Baganator), coordinates under the minimap.
- **This Character:** give a character its own settings.
- **Tools:** open containers, clear loot history or recent runs, unhide all items, clear keep list, reset everything.

## Opening it

- The **eFilter** tab on the vendor window, next to Buyback
- The minimap button, or the addon compartment (the addons button by the minimap)
- `/efilter` or `/esbf`

| Command | What it does |
| --- | --- |
| `/efilter` | Toggle the window |
| `/efilter lockouts` | Open the Lockouts tab |
| `/efilter settings` | Open the Settings tab |
| `/efilter minimap` | Show or hide the minimap button |
| `/efilter center` | Move the window back to the middle of the screen |
| `/efilter debug` | Print diagnostic info (hover an item first to include it) |
| `/efilter reset` | Erase all settings and history (asks first) |
| `/efilter help` | List commands |

## Development

- `luacheck .` checks every file for typos and undefined globals (config in `.luacheckrc`). GitHub runs it on every push.
- `/efilter debug` prints what the addon sees in the game: price source, vault data, keystone, current run, and details of the item under your cursor.

## Translating

All text is in English by default. To add a language, add a block for its locale to `Locales.lua`; anything not translated shows in English.

## Releasing

The text and screenshot list for a CurseForge or Wago page is in `docs/curseforge.md`.


1. Update `## Version` in `eSaithBagFilter.toc` and add a section to `CHANGELOG.md`.
2. Tag the commit and push the tag, e.g. `git tag v2.1.0` then `git push origin v2.1.0`.
3. The GitHub Actions release workflow builds the zip and attaches it to a GitHub release. To also publish to CurseForge or Wago, follow the steps at the top of `.github/workflows/release.yml`.

## Credits

- Stepphy (Nathezrim): first tester. Helped move the original design away from depending on the default bags so it works with any bag addon.
- JuniorDeBoss: helped with tooltip bugs and reducing spam.
- Podden: helped with more tooltip bugs from addons that make heavy use of tooltips.
- Guild Master: feedback on the overall product.
- _Max_Cavalera_: suggested the "Keep all BoE" option.
