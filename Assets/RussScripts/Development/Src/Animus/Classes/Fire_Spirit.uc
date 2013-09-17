/* Tank you to http://www.moug-portfolio.info/udk-ai-pawn-movement/
 * for code
*/

class Fire_Spirit extends Animus_Pawn
    placeable;

var() int bump_timer;
var() int bump_damage;
var() name FlameTemplate;
    
function AddDefaultInventory()
{
    // insert logic to determine item drops
    // InvManager.CreateInventory();
    
    local int              item_seed;
    local Animus_Inventory pawn_drop;
    
    item_seed = Rand(100);
    pawn_drop = None;
    
    if (item_seed <5)
    {
        pawn_drop=Spawn(class'Item_Ring', self);
    }
    else if (item_seed < 20)
    {
        pawn_drop=Spawn(class'Item_HealthPotion', self);
    }
    
    if (pawn_drop != None)
        pawn_InvManager.AddItem(pawn_drop);
}

/* generate stats for pawn given the current levels
 * This is used for enemy spawning
 * OVERRIDDEN FOR FIRE_SPIRIT
 */
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
    pawn_stats.physical_res = 10; // 90% damage from physical attacks
    pawn_stats.fire_res = 15; // 75% damage from fire
    pawn_stats.wind_res = 0;
    pawn_stats.lightning_res = 0;
    
    pawn_exp_reward = pawn_level * 5;
    
    /* calculate pawn max health/stamina */
    pawn_health[1] = 100 + pawn_level * 10;
    pawn_fire_stamina[1] = 100 + (pawn_fire_level * 20);
    pawn_lightning_stamina[1] = 0;
    pawn_wind_stamina[1] = 0;

    pawn_health[0]=pawn_health[1];
    pawn_fire_stamina[0]=pawn_fire_stamina[1];
    pawn_lightning_stamina[0]=pawn_lightning_stamina[1];
    pawn_wind_stamina[0]=pawn_wind_stamina[1];
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
    
    generateStats();
    AddDefaultInventory();
}

simulated event allow_bump()
{
    bump_timer = 0;
}

simulated event Bump( Actor Other, PrimitiveComponent OtherComp, Vector HitNormal )
{
    local Animus_Pawn P;

    Super.Bump( Other, OtherComp, HitNormal );

    /* if the hit object is not a skel mesh */
	if ( (Other == None) || Other.bStatic )
		return;

    P = Animus_Pawn(Other); // the pawn we might have bumped into

	if ( P != None && P.bIsPlayer && bump_timer == 0)  // if we hit the player and bump_timer expired
	{
        `Log("Bump");
        bump_timer = 1;
        SetTimer(1, false, 'allow_bump');
        P.TakeDamage(calculateDamage(FIRE_DAMAGE, bump_damage), Controller, Location, HitNormal, class'Fire_DamageType', , self);
    }
}

defaultproperties
{
    Begin Object Name=CollisionCylinder
        CollisionRadius=32
        CollisionHeight=+44.000000
    End Object
 
    Begin Object Class=StaticMeshComponent Name=FireSpiritStaticMesh
        StaticMesh=StaticMesh'Spirits.element_ball'
        // no animation set for the fire spirit
        //AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
        //AnimTreeTemplate=AnimTree'SandboxContent.Animations.AT_CH_Human'
        HiddenGame=FALSE
        HiddenEditor=FALSE
    End Object
 
    // its not a skeletal mesh, so if we find we need a reference to it we will need to make our own
    // member variable to store the StaticMesh
    //Mesh=FireSpiritSkeletalMesh
 
    Components.Add(FireSpiritStaticMesh)
    CollisionComponent=FireSpiritStaticMesh
    ControllerClass=class'Animus.Animus_EnemyController'
    InventoryManagerClass=class'Animus.Animus_InventoryManager'

    Begin Object Class=ParticleSystemComponent Name=ParticleFlame
        Template=ParticleSystem'Spirits.flame'
        bAutoActivate=true
        scale=2.7
    End Object    
    
    FlameTemplate=ParticleFlame
    Components.Add(ParticleFlame)
    
    bJumpCapable=false
    bCanJump=false
 
    GroundSpeed=300.0 //Making the bot slower than the player
    
    // can only use fire magic, go figure

    pawn_spell_info(0)={(spell1=(enabled=1),  // Fireball
                         spell2=(enabled=1),  // Heat Wave
                         spell3=(enabled=1),  // Fire Storm
                         can_use=1
                       )}
    
    bump_timer=0
    pawn_level=3
    pawn_fire_level=3
    bump_damage=11
}