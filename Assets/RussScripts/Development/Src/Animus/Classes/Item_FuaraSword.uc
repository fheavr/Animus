/* This class defines the sword object that can be dropped for the player
 * to hold in their inventory */
 
 // thanks here for inventory help:
 // http://www.youtube.com/watch?v=nARsePHxYLg

class Item_FuaraSword extends Animus_Inventory;

defaultproperties
{
    equip_name="Fuara_Sword"
    equip_type=1
    
    // overriding previously defined so dont specify class
	Begin Object Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor' // TODO: update this sprite
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Inventory"
	End Object
	Components.Add(Sprite)

    Begin Object Class=SkeletalMeshComponent Name=PickupMesh
        SkeletalMesh=SkeletalMesh'WeaponPackage.firemastersword'
        Scale=0.2
    End Object
    Components.Add(PickupMesh)
    
    DroppedPickupMesh=PickupMesh
    PickupFactoryMesh=PickupMesh
    
    DroppedPickupParticles=None
    
    equip_class=class'Animus_FuaraSword'
}