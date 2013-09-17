/* This system manages how items are added/used within the players inventory
 * 
 * Thanks to 
 * http://www.youtube.com/watch?v=nARsePHxYLg
 * http://forums.epicgames.com/threads/818072-Inventory-Tutorial
 */

class Animus_InventoryManager extends InventoryManager;

var array<Animus_Inventory> InventoryItems; // actual array of inventory items (fixed size)
var int                     NumItems;
var int                     MaxItems;

var array<Animus_Inventory> EquippedItems;   // Equipped weapon item
var int                     eNumItems;
var int                     eMaxItems;
var	Animus_Weapon           EquippedWeapon; // currently equipped weapon

/** the amount of gold held within this character's inventory */
var int gold;
var int max_gold;

event PostBeginPlay()
{
	Super.PostBeginPlay();
	Instigator = Pawn(Owner);
    InventoryItems.Length=MaxItems;
    EquippedItems.Length=eMaxItems;
}

function AddGold(int goldAmount)
{
    if(gold + goldAmount >= max_gold)
    {
        gold = max_gold;
    }
    else
    {
        gold += goldAmount;
    }
}

function Use_Item(Animus_Inventory Item)
{
    local int i;

    // check if the item is useable
    if (Item.equip_type != 0)
        return;
        
    if (Item == None)
    {
        `log("Cannot use item 'None'\n");
        return;
    }
    
    // check that the item is in inventory
        // check if the item is in the inventory
    for (i = 0; i < MaxItems; i++)
    {
        if (InventoryItems[i] == Item)
            break;
    }
    
    if (i >= MaxItems)
    {
        `log("Cannot equip an item that is not in your inventory\n");
        return;
    }
    
    // call use function
    InventoryItems[i].Use();
}

function Equip(Animus_Inventory Item)
{
    local int i;

    // item is a potion
    if (Item.equip_type == 0)
    {
        `log("Cannot equip this item: "@Item@"\n");
        return;
    }
    
    // check if the item is in the inventory
    for (i = 0; i < MaxItems; i++)
    {
        if (InventoryItems[i] == Item)
            break;
    }
    
    if (i >= MaxItems)
    {
        `log("Cannot equip an item that is not in your inventory\n");
        return;
    }
    
    if (Item.equip_type == 1) // if sword
    {
        if (EquippedWeapon != None)
        {
            EquippedWeapon.Destroy();
        }
    
        EquippedWeapon=Spawn(Item.equip_class, Owner);
        EquippedWeapon.AttachWeaponTo(Pawn(Owner).Mesh);
        InventoryItems[i] = EquippedItems[0];
        EquippedItems[0] = Item;

    }
    else if (Item.equip_type == 2)
    {
        InventoryItems[i] = EquippedItems[1];
        EquippedItems[1] = Item;    
    }
    
    if (InventoryItems[i] == None)
    {
        NumItems--;
        eNumItems++;
    }
}

function Unequip(Animus_Inventory Item)
{
    local int i;
    local int j;
    
    if (Item.equip_type == 1) // if sword
    {
        // cannot remove sword
        return;
    }
    
    // check if the item is equipped
    for (i = 0; i < eMaxItems; i++)
    {
        if (EquippedItems[i] == Item)
            break;
    }
    
    // check if there is space in the inventory
    for (j = 0; j < MaxItems; j++)
    {
        if (InventoryItems[j] == None)
            break;
    }
    
    if (i >= MaxItems || j >= eMaxItems)
    {
        `log("Cannot unequip\n");
        return;
    }
    
    if (Item.equip_type == 2) // if ring
    {
        InventoryItems[j] = EquippedItems[i];
        EquippedItems[i] = None;
    }
    else
    {
        `log("ERROR, should not get here\n");
    }
    
    if (EquippedItems[i] == None)
    {
        eNumItems--;
    }
}

/**
 * Setup Inventory for Pawn P.
 * Override this to change inventory assignment (from a pawn to another)
 * Network: Server only
 */
function SetupFor(Pawn P)
{
	Instigator = P;
	SetOwner(P);
}


/**	Event called when inventory manager is destroyed, called from Pawn.Destroyed() */
event Destroyed()
{
	DiscardInventory();
}

/** allows the rearranging of the player's inventory and is also used for equipment changing */
function bool SwapItems(Animus_Inventory Item1, Animus_Inventory Item2)
{
    local int i;
    local int index1;
    local int index2;
    local Animus_Inventory tmp;
    
    for (i = 0; i < MaxItems; i++)
    {
        if (InventoryItems[i] == Item1)
            index1 = i;
            
        if (InventoryItems[i] == Item2)
            index2 = i;
    }
    
    if (index1 == index2)
        return false;
    
    tmp = InventoryItems[index1];
    InventoryItems[index1] = InventoryItems[index2];
    InventoryItems[index2] = tmp;
    
    return true;
}

/**
 * Adds an existing inventory item to the list.
 * Returns true to indicate it was added, false to indicate your inventory is full
 *
 * @param	NewItem		Item to add to inventory manager.
 * @return	true if item was added, false otherwise.
 */
simulated function bool AddItem(Animus_Inventory NewItem)
{
    local int i;
    
    // check for stackable items
    if (NewItem.bStackable == true)
    {
        // TODO: iterate through items checking quantities and types
        // if (exists & enough quantity)
        //     add and return
    }
    
    // check to see if there is an empty slot
    if (NumItems == MaxItems)
        return false;
    
    // find empty spot and add
    for (i = 0; i < InventoryItems.Length; i++)
    {
        if (InventoryItems[i] == None)
        {
            InventoryItems[i] = NewItem;
            break;
        }        
    }
    NumItems++;
}

/**
 * Attempts to remove an item from the inventory list if it exists.
 *
 * @param ItemToRemove Item to remove from inventory
 */
simulated function RemoveItem(Animus_Inventory ItemToRemove)
{
    local int i;
    
    for (i = 0; i < InventoryItems.Length; i++)
    {
        if (InventoryItems[i] == ItemToRemove)
        {
            InventoryItems[i] = None;
            break;
        }
    }
    NumItems--;
}


/** called when our owner is killed */
function OwnerDied()
{
    local Animus_Pawn killer;

	Destroy();
    
    killer = Animus_Pawn(Instigator);
	if (killer != None && killer.pawn_InvManager == self)
	{
		killer.pawn_InvManager = None;
	}
}

/**
 * Discard full inventory, generally because the owner died
 */
simulated event DiscardInventory()
{
	local Animus_Inventory Inv;
	local vector           TossVelocity;
	local bool             bBelowKillZ;
    local int              i;

	// don't drop any inventory if below KillZ or out of world
	bBelowKillZ = (Instigator == None);// || (Instigator.Location.Z < WorldInfo.KillZ);
    
    for (i = 0; i < InventoryItems.Length; i++)
    {
        Inv = InventoryItems[i];
        if (Inv == None)
            continue;
            
		if( Inv.bDropOnDeath && !bBelowKillZ )
		{
			TossVelocity = vector(Instigator.GetViewRotation());
			TossVelocity = TossVelocity * ((Instigator.Velocity dot TossVelocity) + 500.f) + 250.f * VRand() + vect(0,0,250);
			Inv.DropFrom(Instigator.Location, TossVelocity);
		}
        else
        {
            Inv.Destroy();
        }
    }
}

defaultproperties
{
    MaxItems=8
    NumItems=0
    eMaxItems=2
    eNumItems=0
}