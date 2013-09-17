/* This class is responsible for keeping track of items within the players
 * inventory and defines a set of restrictions to be applied to this
 * inventory */
 
 // Thanks to here for help with the invoentory:
 // http://www.youtube.com/watch?v=nARsePHxYLg

class Animus_Inventory extends Inventory;

var string                  equip_name;

/*
 * 0 -- generic item
 * 1 -- weapons
 * 2 -- rings
 */
var int                     equip_type;
var bool                    bStackable;
var int                     Quantity; // the number of this item you posses (for stackable items)
var class<Animus_Weapon>    equip_class; // the class to spawn when the player equips this item
var Animus_Pawn             holder;

simulated function String GetName()
{
	return equip_name;
}

function Use()
{/* override to use */}

event Destroyed()
{
	// Notify Pawn's inventory manager that this item is being destroyed (remove from inventory manager).
	if ( Animus_Pawn(Owner) != None && Animus_Pawn(Owner).pawn_InvManager != None )
	{
		Animus_Pawn(Owner).pawn_InvManager.RemoveItem( Self );
	}
}

/* GiveTo:
	Give this Inventory Item to this Pawn.
	InvManager.AddInventory implements the correct behavior.
*/
function aGiveTo( Pawn Other )
{
    local Animus_Pawn pawn;
    pawn = Animus_Pawn(Other);
    
	if ( Other != None && pawn.pawn_InvManager != None )
	{
		pawn.pawn_InvManager.AddItem( Self );
        holder=pawn;
	}
}

defaultproperties
{
	Begin Object Class=SpriteComponent Name=DefaultSprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Inventory"
	End Object
	Components.Add(DefaultSprite)

	DroppedPickupClass=class'Animus_DroppedPickup'
    
    bStackable=false
    bDropOnDeath=true
    equip_class=None
    equip_name=""
    equip_type=0
    holder=None
}
