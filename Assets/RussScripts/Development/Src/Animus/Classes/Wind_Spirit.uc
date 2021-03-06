/* Tank you to http://www.moug-portfolio.info/udk-ai-pawn-movement/
 * for code
*/

class Wind_Spirit extends Animus_Pawn
    placeable;

var() int bump_timer;
var() int bump_damage;
    
function AddDefaultInventory()
{
    // insert logic to determine item drops
    // InvManager.CreateInventory();
}

/* generate stats for pawn given the current levels
 * This is used for enemy spawning
 * OVERRIDDEN FOR WIND_SPIRIT
 */
function generateStats()
{
    pawn_stats.atk = 1;
    pawn_stats.def = pawn_level;
    pawn_stats.spd = 1;
    pawn_stats.crit = 0;
    pawn_stats.luck = 0;
    pawn_stats.fire_atk = 0;
    pawn_stats.lightning_atk = 0;
    pawn_stats.wind_atk = pawn_wind_level * 2;
    pawn_stats.fire_def = 2 * pawn_level;
    pawn_stats.wind_def = 2 * pawn_level;
    pawn_stats.lightning_def = pawn_level;
    pawn_stats.physical_res = 80; // 20% damage from physical attacks
    pawn_stats.fire_res = 95;     // 5% damage from fire attacks 
    pawn_stats.wind_res = 50;      // 50% damage from wind attacks
    pawn_stats.lightning_res = 0;
    
    pawn_exp_reward = pawn_level * 5;
    
    /* calculate pawn max health/stamina */
    pawn_health[1] = 40 + pawn_level * 5;
    pawn_fire_stamina[1] = 0;
    pawn_lightning_stamina[1] = 0;
    pawn_wind_stamina[1] = 100 + (pawn_wind_level * 15);

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
        P.TakeDamage(bump_damage, Controller, Location, HitNormal, class'Wind_DamageType', , self);
    }
}

defaultproperties
{
    Begin Object Name=CollisionCylinder
        CollisionRadius=32
        CollisionHeight=+44.000000
    End Object
 
    Begin Object Class=StaticMeshComponent Name=WindSpiritStaticMesh
        StaticMesh=StaticMesh'Spirits.wind_ball_d2'
        // no animation set for the wind spirit
        // AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
        // AnimTreeTemplate=AnimTree'SandboxContent.Animations.AT_CH_Human'
        HiddenGame=FALSE
        HiddenEditor=FALSE
    End Object
 
    // its not a skeletal mesh, so if we find we need a reference to it we will need to make our own
    // member variable to store the StaticMesh
    // Mesh=WindSpiritSkeletalMesh
 
    Components.Add(WindSpiritStaticMesh)
    CollisionComponent=WindSpiritStaticMesh
    ControllerClass=class'Animus.Animus_EnemyController'
    InventoryManagerClass=class'Animus.Animus_InventoryManager'

    // TODO: add wind particle effect
    
    bJumpCapable=false
    bCanJump=false
 
    GroundSpeed=300.0 //wind spirits are moderately fast (relative to player)
    
    // can only use wind magic
    pawn_spell_info(2)={(spell1=(enabled=1),  // Lightningbolt
                         spell2=(enabled=1),  // Chain Lightning
                         spell3=(enabled=1),  // 
                         spell4=(enabled=1),  // Tornado
                         can_use=1
                       )}
    
    bump_timer=0
    pawn_level=3
    pawn_wind_level=3
    bump_damage=5
}