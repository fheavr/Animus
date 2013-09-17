/* This class defined the Inventory basic ring equipment */
class Item_Ring extends Animus_Inventory;

defaultproperties
{
    equip_name="Simple Ring"
    equip_type=2

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
        StaticMesh=StaticMesh'Misc_Items.Ring'
        Scale=10.0
        Translation=(Z=-25)
    End Object
    Components.Add(PickupMesh)
    
    DroppedPickupMesh=PickupMesh
    PickupFactoryMesh=PickupMesh
    
    DroppedPickupParticles=None
}