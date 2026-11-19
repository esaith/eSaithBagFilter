# eSaith Bag Filter

Sell the loot you picked up by **zone** and **quality**, protect the things you want to keep, and see which of your characters are **saved** to which raids and dungeons.

Updated for **World of Warcraft: Midnight** (12.1.x).

## Features

**Loot tab**
- Everything you loot is remembered along with the zone (or dungeon/raid) it came from.
- Pick a zone from the dropdown (or *All zones*) and toggle qualities on the left: Poor, Common, Uncommon, Rare, Epic.
- Items are grouped by quality with their stack counts. The status bar shows how much they'll sell for.
- **Click an item to keep it.** Kept items are faded, show a lock, and are never sold. Shift-click to link an item, Ctrl-click to preview it.
- At a vendor, press **Sell Items** to sell everything shown that isn't faded.
- Always protected: anything you've equipped, and anything in an equipment set.

**Lockouts tab**
- A grid of your characters (class colored) against every instance they're saved to, with the time left until each save resets.
- Log in on each character once and they're added automatically.

**Settings tab**
- Selling: auto-sell junk, keep green/blue/epic BoE items, keep trade goods, open with vendor.
- Looting: quick loot, auto-greed green items, remember loot after logout.
- Extras: quest helper (hold Shift to skip it), coordinates under the minimap.
- Tools: open containers, clear loot history, clear keep list, reset everything.
- Choose which characters and instances appear on the Lockouts tab.

## Opening it

- The **eFilter** tab on the vendor window, next to Buyback
- The addon compartment (the addons button by the minimap)
- `/efilter` or `/esbf`

| Command | What it does |
| --- | --- |
| `/efilter` | Toggle the window |
| `/efilter lockouts` | Open the Lockouts tab |
| `/efilter settings` | Open the Settings tab |
| `/efilter center` | Move the window back to the middle of the screen |
| `/efilter reset` | Erase all settings and history (asks first) |
| `/efilter help` | List commands |

## Changelog

### 2.0.0 (Midnight)
Rewritten for the Midnight API and given a new interface. Your settings, keep list, loot history and lockouts carry over automatically.

**New look**
- Standard Blizzard-style window with a portrait, title and resize grip (drag the bottom-right corner). Size and position are remembered.
- Three tabs: Loot, Lockouts and Settings. Settings used to hide behind a cog.
- Native item buttons with quality borders, stack counts and a lock icon on kept items.
- The Lockouts grid shows time left on each save and class colors.
- Option descriptions are in tooltips, and the Settings tab is split into sections.

**Midnight / API updates**
- Interface version 120105.
- Loot is now tracked by watching your bags change. Midnight hides loot chat messages from addons inside instances, which broke per-dungeon tracking. This also means it works in every game language.
- Dropdowns use the new Menu system (`WowStyle1DropdownTemplate`). The old `UIDropDownMenu` code is gone.
- Item details now come from Blizzard's bag and item data instead of English text like "Trade Goods", so they work in any language.
- Values Midnight may hide from addons are checked before use (`issecretvalue`).
- Addon compartment support and a TOC icon.
- LibStub, CallbackHandler and lib-st are no longer needed.

**Fixes**
- Opening containers called a function removed in Dragonflight, and its loop stopped running once the vendor window closed.
- Turning coordinates off didn't save.
- The window couldn't be kept on screen (`IsClampedToScreen` was used where `SetClampedToScreen` was meant).
- Quick loot tried to loot one slot too many.
- The quest helper called `AcceptQuest` on quests you'd already accepted, and checked rewards instead of reward choices.
- Auto-greed could error on uncached items. It now reads the roll's own item info and only greeds when Greed is allowed.
- Options added in later versions got no default for players upgrading from older versions.
- Reset now asks for confirmation.
- Items in the reagent bag are included.

**New options**
- Keep epic BoE items.

## Credits

- Stepphy (Nathezrim): first tester. Helped move the original design away from depending on the default bags so it works with any bag addon.
- JuniorDeBoss: helped with tooltip bugs and reducing spam.
- Podden: helped with more tooltip bugs from addons that make heavy use of tooltips.
- Guild Master: feedback on the overall product.
- _Max_Cavalera_: suggested the "Keep all BoE" option.

## Older versions

```text
  1.38
	Update for BFA 8.0
	Reverted Hitem to link

	Added Features
		Added character list on options panel to toggle which characters to view when viewing saved dungeons.
		When 'Do not sell Uncommon or Trade Goods', the alpha should be apparent as if the user manually click the item. The item is not included on the kept list, though

	Fixed Issues
		Fixed scrolling on Raid Info list. When scrolling with the mouse wheel, the scroll nob scrolls as well
		After closing the options tab, the bottom tab now shows the items tab correctly instead of defaulting to Raid Info tab

  1.37
	Update for 7.3. 
	Significant code update.
		Changed saving items from 'link' to 'Hitem'
	
	Added/Updated Features
		After user selects an option from a drop down, the selected item is now saved as the new drop down title 
		All gear currently worn is automatically added to the players kept list. This should provide additional security that items should not be sold. 
		
		Raid Info
			User may now filter this list to view which characters are saved to which instance. This is provided in the options panel
			Saved instances are now in a tabular format instead of string based.
			If no instances are chosen then a info message lets the user know where to update this list.

	Removed Items
		iLevel fitler
		Removed artwork background. Images are cool but deters from actual use of Addon
		Removed background colors for items. Should be reintroduced after Hitem fix
		BOE section removed. Should be reintroduced after Hitem fix
	
	Known Issues
		Scrolling on Raid Info raw list with middle mouse does not update scroll position
		Occasionally items are not shown properly per zone.
		After closing the options the bottom tab defaults to the Raid Info tab.
 1.36
	Fixed issue with variables from v1.32 to v1.36 This fixed the issue when selecting "Keep all BOE" option would cause LUA error
    Fixed issue when updating the AddOn to a higher version all instance and raid info would be erased.
    Fixed issue where hovering over non-link item (e.g. profession enchant that is not an item) an error would occur.


  1.35    
	Instances and player names are sorted alphabetically
	Fixed issue when one of the items is a pet would cause a popup error
    When opening options all other tabs, panels, buttons, etc that are not directly related to options is hidden. This should help reduce confusion of 
        which tab and information the player receives and then when attempting to navigate to another tab.
    Added "Quest Complete" which quickly obtains and completes quests. Excellent for leveling! Quest rewards are randomly chosen. 
    Added "Keep All BOE" checkbox. When checked every BOE of Uncommon quality (Green) or greater is immediately put in the kept list
    Prevents the "Item is busy" error from occurring when selling items
 
  1.34
     Updated for Legion expansion
	 Loot Frame
		 Added a loot frame so that looted items now appear in a separate frame than the main frame
		 Background of loot frame may be enabled/disabled. Enabled by default. If disabled a default of a black background is shown		
		 Background images change with each new session. Up to 50+ different images can be seen
		 The loot frame will have a minimum size close to that of the main frame. If the number of items start to exceed the size then the loot frame should increase in size so accommodate the number of items
		 All images are the property of Blizzard. None of them are the authors art work. These images are located inside the game client
	 Side tabs have been removed for a cleaner 1 page look
	 The options tab is now the cog-wheel located on the top right corner
	-Zone dropdown
		 Slight addition the way the dropped down works for zoning. If all items are desired, then the player must choose "ALL" to view the all items (replaces 3rd tab)
		 When selecting a zone/instance all filters are enabled. The player may now filter on zones
		 The capability to filter by iLevel is available. Off by default. The player may choose the to turn this option on in the options panel. Same filtering applies from prior version

 1.33
  Updated global variables to use local variables for easy writing and shorter lines of code.  
     Added Auto greed on green items 
	 Included background colors to selected filtered items to more easily distinquish which levels are which rarities
	 Increased the base height of the addon so that it doesn't jump as much when 
	 Moved the Do Not Sell Trade Goods to the options page. Now all filtering pages have that option.
		 When checkbox is marked all trade goods are added to a secondary saved list and become transparent like the normal trade goods. If Trade Goods becomes unmarked then all items will lose their transparency unless they are saved by the manual toggle (normal kept list)
	 When Reset now does not reload the game. 
	 Included items that don't have 'bind on pickup', 'bind on pick up', or 'soulbound' in the item description. This should help with other items such as patterns 
	
 1.32
	 The issue with the tooltip looking funny while looting should now be resolved. The likely culprit is due to other addons that support and extend extensive tooltip options (multiple boxes). Since the BOE/BOP is checked by using the tooltip and that the tooltip is modified by using other addons, the tooltip is now hidden after reading.  

 1.31
     Fixed issue when getting items from the mailbox. The tooltip would look and act funny
     Added more detailed information to raid instances. This should help distinguish between 5 man dungeons with heroic and mythic availability

 1.3 
    Auto loot all containers. If room is not available a message is printed in the chat box.
       ** Currently this does not include salvage boxes, or any container that has a cast time.
     Make loot buttons smaller and increased the number per row
     Better fitting frame to number of items.
     Organzied items by rarity. Lowest quality up top, highest quality on bottom
     Added an options panel
     Added Coordinates to be turned off/on that is located under the mini-map
     Fixed issue where addon would appear to 'jump' when going from tab to the next
     Added Auto-sell junk items when first talking to a vendor
     Addon auto-updates internal variables when it recognizes its an older version that current installed. When updating any saved lists should still be saved
     Prevented addon from immediately opening when talking to a vendor (even the programmer got annoyed)
         Added button to Merchant Frame to toggle addon open/close
     Added auto addon update depending on its version.
     When scrolling over items a comparison to equipped items can be made by pressing any <Shift> button
     Added BOE section that removes all BOE items of rare (blue) quality or higher to the bottom of the list for easier filtering
         Included in options page to include green (if so desired)
     Added reset command line in case the user is unable to do from button

1.2 Moved the items options from the bag to the actual addon. Should reduce the chance of interfering with other bag addons or addons that do similar functions. Instead of seeing all items and then dimming those that 
 are wished to be sold, only the items will appear that contain to the selected tab - then the player may select the item to keep it on the list
 This list is updated once all items are sold; yet, if an item is added to the bags after selected checkboxs have marked then those items likely won't show up until the next change in checkboxes occurs.

1.1 Added tab #4, Player/Character Info. Reset Addon Button. View instance resets for all characters. For the character raids/instances to show they player only needs to log in 
 and is not required to open the addon. Only instances that have a heroic mode or higher and if the character is level 70 or higher

1.0 
 Initial Version 3 tabs (Zone, iLVL, Rarity). Allows mass auto-sell. 
 "Keep item" when addon is visible. ALT + Click item, blue haze adds item to auto-sellable list. Alt + Click again to unlink it
```
