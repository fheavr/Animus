/* This class defines the basic health potion inventory item */
class Item_HealthPotion extends Animus_Inventory;

function Use()
{
    holder.pawn_health[0] += 20;
    if (holder.pawn_health[0] > holder.pawn_health[1])
        holder.pawn_health[0] = holder.pawn_health[1];
}

defaultproperties
{
    equip_name="Health Potion"
    equip_type=0

    // overriding previously defined so dont specify class
	Begin Object Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor' // TODO: update this sprite
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Inventory"
	End Object
	Components.Add(Sprite)

    Begin Object Class=StaticMeshComponent Name=PickupMesh
        StaticMesh=StaticMesh'Misc_Items.potion'
    End Object
    Components.Add(PickupMesh)
    
    DroppedPickupMesh=PickupMesh
    PickupFactoryMesh=PickupMesh
    DroppedPickupParticles=None
}