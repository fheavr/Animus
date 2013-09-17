// Thanks http://udn.epicgames.com/Three/CameraTechnicalGuide.html for the isometric camera
// http://forums.epicgames.com/threads/750868-UDK-action-game-3rd-person-camera-code for the movement

class Hero extends Animus_Pawn
  placeable;

//var name WeaponSocket; already exists in UTPawn superclass
  
/* Level 1 Stats for Hero
 */
function generateStats()
{
    pawn_stats.atk = 1;
    pawn_stats.def = pawn_level;
    pawn_stats.spd = 1;
    pawn_stats.crit = 0;
    pawn_stats.luck = 0;
    pawn_stats.fire_atk = 2;
    pawn_stats.lightning_atk = 0;
    pawn_stats.wind_atk = 0;
    pawn_stats.fire_def = 1;
    pawn_stats.wind_def = 1;
    pawn_stats.lightning_def = 1;
    pawn_stats.physical_res = 0;
    pawn_stats.fire_res = 0;
    pawn_stats.wind_res = 0;
    pawn_stats.lightning_res = 0;
    
    /* hero default health/stamina are 
     * the same as base pawn */
} 

//stop aim node from aiming up or down
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
	AimNode.bForceAimDir = true; //forces centercenter
    
    /* Derive the Attack slot from the animation tree assigned
         * to the skeletal model*/
    AttackSlot = AnimNodeSlot(SkelComp.FindAnimNode('AttackSlot'));
}

simulated event PostBeginPlay()
{
    // TODO: populate inventory
    Super.PostBeginPlay();
    Origin.z += 70;
    generateStats();
}

function AddDefaultInventory()
{
    // ex: InvManager.CreateInventory(class'Animus.Animus_InventoryManager');
    //     Stuff that is added to the inventory
    local Animus_Inventory pawn_weapon;
    pawn_weapon=Spawn(class'Item_Sword', self);
    
    pawn_InvManager.AddItem(pawn_weapon);
    pawn_InvManager.Equip(pawn_weapon);
    bWeaponAttachmentVisible=true;
}

public function upgradeArmor()
{
    switch(pawn_armor_state)
    {
        case 0:
            Mesh.SetMaterial(8, MaterialInterface'UDKR_Textures_03_Nobiax.Materials.M_033_Stone');
            pawn_armor_state++;
            break;
        case 1:
            Mesh.SetMaterial(8, MaterialInterface'UDKR_Textures_06_Nobiax.Materials.M_081_VictorRock');
            pawn_armor_state++;
            break;
        default: // return to the basic armor
            Mesh.SetMaterial(8, MaterialInterface'UDKR_Textures_06_Nobiax.Materials.M_081_VictorRock');
            pawn_armor_state = 0;
            break;
    }
}

/* If we want our camera to rotate with the player:
 * Courtesy of http://www.mavrikgames.com/tutorials/melee-weapons/melee-weapon-tutorial-part-1
  */
simulated function bool CalcCamera(float DeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV)
{
    local Vector HitLocation, HitNormal;

    // offsets along the pitch vector
    out_CamLoc = Location;
    out_CamLoc.X -= Cos(Rotation.Yaw * UnrRotToRad) * Cos(CamPitch * UnrRotToRad) * CamOffsetDistance - CamFixedOffset[0];
    out_CamLoc.Y -= Sin(Rotation.Yaw * UnrRotToRad) * Cos(CamPitch * UnrRotToRad) * CamOffsetDistance - CamFixedOffset[1];
    out_CamLoc.Z -= Sin(CamPitch * UnrRotToRad) * CamOffsetDistance - CamFixedOffset[2];

    // offsets along X axis relative to player orientation
    // make the camera shift to the right of the player
    out_CamLoc.X -= Sin(Rotation.Yaw * UnrRotToRad) * 90;
    out_CamLoc.Y += Cos(Rotation.Yaw * UnrRotToRad) * 90;  
    
    out_CamRot.Yaw = Rotation.Yaw;
    out_CamRot.Pitch = CamPitch;
    out_CamRot.Roll = 0;

    if (Trace(HitLocation, HitNormal, out_CamLoc, Location, false, vect(12, 12, 12)) != none)
    {
        out_CamLoc = HitLocation;
    }

    return true;
}

simulated singular event Rotator GetBaseAimRotation()
{
    local rotator   POVRot, tempRot;

    tempRot = Rotation;
    tempRot.Pitch = 0;
    SetRotation(tempRot);
    POVRot = Rotation;
    POVRot.Pitch = 0;
    

    return POVRot;
}

defaultproperties
{
    IsoCamAngle=6820 // < 35.264 degrees
    CamOffsetDistance=384.0
    CamFixedOffset(0)=0
    CamFixedOffset(1)=0
    CamFixedOffset(2)=160

    Begin Object Class=CylinderComponent Name=CylinderComp
        CollisionRadius=32
        CollisionHeight=90
        CollideActors=true        
        BlockActors=true
    End Object
    
    Components.Add( CylinderComp )
    CollisionComponent=CylinderComp   

    // default NPC mesh
    Begin Object Class=SkeletalMeshComponent Name=Hero_Mesh
        SkeletalMesh=SkeletalMesh'Characters.Hero'
        //LightEnvironment=ZombLightEnvironment
        PhysicsAsset=PhysicsAsset'CH_AnimCorrupt.Mesh.SK_CH_Corrupt_Male_Physics'
        AnimSets(0)=AnimSet'Characters.Male_Relaxed_Stand'
        AnimSets(1)=AnimSet'Characters.Male_Walking'
        AnimSets(2)=AnimSet'Characters.Male_Jump'
        AnimSets(3)=AnimSet'Characters.Male_Climb'
        AnimSets(4)=AnimSet'Characters.Male_Cast'
        AnimSets(5)=AnimSet'Characters.Male_Slash'
        AnimtreeTemplate=AnimTree'Characters.Default_Male'
        Scale=0.6
        Translation=(Z=-95)

    End Object
  
    Mesh=Hero_Mesh
    Components.Add(Hero_Mesh)

    // Points to your custom AIController class - as the default value
    // will probably never be used as the player will always control this player
    ControllerClass=class'Animus.Animus_AllyController'
    InventoryManagerClass=class'Animus.Animus_InventoryManager'
    bIsPlayer=true
    
    GroundSpeed=750.0
    
    JumpZ = 500
    
    pawn_health_regen=5
    
    pawn_name="Fallon"
    
    /* enable the player's first spell */
    pawn_spell_info(0)={(spell1=(enabled=1),  // Fireball
                         spell2=(enabled=0),  // Heat Wave
                         spell3=(enabled=0),  // Fire Storm
                         can_use=1
                   )}

}