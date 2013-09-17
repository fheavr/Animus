/* Tank you to http://www.moug-portfolio.info/udk-ai-pawn-movement/
 * for code
*/

class Fire_Spirit_Boss extends Fire_Spirit
    placeable;
    
function AddDefaultInventory()
{
    // insert logic to determine item drops
    // InvManager.CreateInventory();
    local Animus_Inventory pawn_weapon;
    pawn_weapon=Spawn(class'Item_FuaraSword', self);
    
    pawn_InvManager.AddItem(pawn_weapon);
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
}

function generateStats()
{
    pawn_stats.atk = 1;
    pawn_stats.def = pawn_level;
    pawn_stats.spd = 1;
    pawn_stats.crit = 0;
    pawn_stats.luck = 0;
    pawn_stats.fire_atk = pawn_fire_level * 2;
    pawn_stats.lightning_atk = 0;
    pawn_stats.wind_atk = 0;
    pawn_stats.fire_def = pawn_level;
    pawn_stats.wind_def = pawn_level;
    pawn_stats.lightning_def = pawn_level;
    pawn_stats.physical_res = 25; // half damage from physical attacks
    pawn_stats.fire_res = 55; // 3/4 damage from fire
    pawn_stats.wind_res = 0;
    pawn_stats.lightning_res = 0;
    
    pawn_exp_reward = pawn_level * 5;
    
    /* calculate pawn max health/stamina */
    pawn_health[1] = 100 + pawn_level * 100;
    pawn_fire_stamina[1] = 10 + (pawn_fire_level * 2);
    pawn_lightning_stamina[1] = 0;
    pawn_wind_stamina[1] = 0;

    pawn_health[0]=pawn_health[1];
    pawn_fire_stamina[0]=pawn_fire_stamina[1];
    pawn_lightning_stamina[0]=pawn_lightning_stamina[1];
    pawn_wind_stamina[0]=pawn_wind_stamina[1];
}

defaultproperties
{
    Begin Object Name=CollisionCylinder
        CollisionRadius=32
        CollisionHeight=+44.000000
    End Object
 
    Begin Object Class=StaticMeshComponent Name=FireSpiritBossStaticMesh
        StaticMesh=StaticMesh'Spirits.element_ball'
        // no animation set for the fire spirit
        //AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
        //AnimTreeTemplate=AnimTree'SandboxContent.Animations.AT_CH_Human'
        HiddenGame=FALSE
        HiddenEditor=FALSE
        Scale=4.0
    End Object
    
    Begin Object Class=ParticleSystemComponent Name=ParticleFlameBoss
        Template=ParticleSystem'Spirits.flame'
        bAutoActivate=true
        scale=10.6
        // make the boss look impressive
        LODMethod=PARTICLESYSTEMLODMETHOD_ActivateAutomatic
        EditorLODSetting=0
    End Object    
    
    FlameTemplate=ParticleFlameBoss
    Components.Add(ParticleFlameBoss)

    pawn_level=7
    pawn_fire_level=7
    bump_damage=30
    
    // its not a skeletal mesh, so if we find we need a reference to it we will need to make our own
    // member variable to store the StaticMesh
    //Mesh=FireSpiritSkeletalMesh
 
    Components.Add(FireSpiritBossStaticMesh)
    CollisionComponent=FireSpiritBossStaticMesh
    ControllerClass=class'Animus.Animus_EnemyController'
    InventoryManagerClass=class'Animus.Animus_InventoryManager'
 
    bJumpCapable=false
    bCanJump=false
 
    GroundSpeed=300.0 //Making the bot slower than the player
    
    // Dont need to enable fire, inherited from fire spirit
}