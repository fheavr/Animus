// Thanks http://udn.epicgames.com/Three/CameraTechnicalGuide.html for the isometric camera
// http://forums.epicgames.com/threads/750868-UDK-action-game-3rd-person-camera-code for the movement

// Thanks to here for a lot of the game logic
// http://www.celticwarriors.net/Website/Mirrors/CHiMERiC/Tutorials02/Tut06/UnrealScript%20Tutorial%206%20-%20Nali%20Sorcerer.htm

// Thanks to here for projectile code
// http://forums.epicgames.com/threads/597252-Projectiles-spawn-with-0-velocity

// Thanks to here for how to save
// http://www.mavrikgames.com/tutorials/udk-save-game-system/udk-basic-save-game-tutorial

// Thanks to here for inventory setup
// http://www.youtube.com/watch?v=nARsePHxYLg

class Animus_Pawn extends UTPawn implements (SaveGameStateInterface)
  dependson(Animus_DamageType)
  placeable;

/* ============================
 * = Type Definitions
 * ============================ */ 
  
enum E_ExpType
{
    EXP_HERO,
    EXP_WEAPON,
    EXP_FIRE,
    EXP_LIGHTNING,
    EXP_WIND
};

struct Spell
{
    var byte enabled;
    var float range;
    var int cost;
    var int core_damage;
    var int max_damage;
    var int level_unlock;
    structdefaultproperties
    {
        enabled=0
        range=0
        cost=0
        core_damage=0
        max_damage=0
        level_unlock=0
    }
};

struct Element
{
    var Spell spell1; // first spell of the associated magic type
    var Spell spell2;
    var Spell spell3;
    var Spell spell4;
    var byte can_use; // flag to enable or disable whole element
    structdefaultproperties
    {
        can_use=0
    }
};
  
struct Stats
{
    var int atk;
    var int def;
    var int spd;
    var int crit;
    var int luck;
    var int fire_atk;
    var int wind_atk;
    var int lightning_atk;
    var int fire_def;     // fixed
    var int wind_def;    // fixed
    var int lightning_def; // fixed
    var int physical_res; // percent
    var int fire_res;     // percent
    var int wind_res;    // percent
    var int lightning_res; // percent
};

/* ===============================
 * Local Variables
 * =============================== */

var() const int IsoCamAngle; // pitch angle of the camera
var() const float CamOffsetDistance; // distance to offset the camera from the player
var() const float CamFixedOffset[3];
var() const Name SwordHandSocketName;
var const bool bIsPlayer;
var bool bIsAlly;

var() vector Origin; // the distance from the location variable to consider the 'origin' of the model
var float CamPitch;

// Animation injection slot for attack animations
var() AnimNodeSlot AttackSlot;

// The name of this pawn if applicable
var() string pawn_name;

var() int pawn_regen_rate;
var() int pawn_health_regen;
var() int pawn_stamina_regen;

// first index is current health, second is the maximum health
var() int pawn_health[2];
var() int pawn_fire_stamina[2];
var() int pawn_lightning_stamina[2];
var() int pawn_wind_stamina[2];

var() int pawn_level;
var() int pawn_level_exp[2];
var() int pawn_armor_state;
var() int pawn_weapon_level;
var() int pawn_weapon_exp[2];
var() int pawn_fire_level;
var() int pawn_fire_exp[2];
var() int pawn_lightning_level;
var() int pawn_lightning_exp[2];
var() int pawn_wind_level;
var() int pawn_wind_exp[2];

/* the experience reward upon defeat */
var() int pawn_exp_reward;

/* [0] = Fire Magic
 * [1] = Lightning Magic
 * [2] = Wind Magic
 */
var Element                 pawn_spell_info[3];
var() array<Stats>          armorStatValues;
var() Stats                 pawn_stats;
var Animus_InventoryManager pawn_InvManager;

/* ============================================
 * = Beam logic for Pawns to be able to cast lightning magic 
 * ============================================*/
/** The Particle System Template for the Beam */
var particleSystem BeamTemplate[2];

/** Holds the Emitter for the Beam */
var ParticleSystemComponent BeamEmitter[2];

/** Where to attach the Beam */
var name BeamSockets[2];

/** The name of the EndPoint parameter */
var name EndPointParamName;

/** Animations to play before firing the beam */
var name	BeamPreFireAnim[2];
var name	BeamFireAnim[2];
var name	BeamPostFireAnim[2];

/* =============================================
 * = Pawn Accessors
 * =============================================*/
 
/* GetHealthPercent()
 * returns percent of maximum health
 * of pawn
 */
function float GetHealthPercent()
{
    return pawn_health[0] / pawn_health[1];
}

function int GetFireStamina()
{
    return pawn_fire_stamina[0];
}

function int GetLightningStamina()
{
    return pawn_lightning_stamina[0];
}

function int GetWindStamina()
{
    return pawn_wind_stamina[0];
}
 
/* =============================================
 * = Pawn Regeneration Code
 * = (Must go beforecreation time functions)
 * =============================================*/
simulated event RegenHealth()
{
    //`Log("Tick Function Called with deltaTime="$DeltaTime$"and accum="$AccumulatedTime$"\n");

    if (pawn_health[0] < pawn_health[1])
        pawn_health[0] += pawn_health_regen;
    if (pawn_health[0] < pawn_health[1])
        SetTimer(2, false, 'RegenHealth');
        
    if (pawn_health[0] > pawn_health[1])
    {
        pawn_health[0] = pawn_health[1];
    }
    
}

simulated event RegenStamina()
{
    if (pawn_fire_stamina[0] < pawn_fire_stamina[1])
        pawn_fire_stamina[0] += pawn_stamina_regen;
    if (pawn_lightning_stamina[0] < pawn_lightning_stamina[1])
        pawn_lightning_stamina[0] += pawn_stamina_regen;
    if (pawn_wind_stamina[0] < pawn_wind_stamina[1])
        pawn_wind_stamina[0] += pawn_stamina_regen;
}

/* ================================================
 * = Function calls on Pawn creation 
 * ================================================*/
simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    SetPhysics(PHYS_Falling); // wake up physics
    SetTimer(1, true, 'RegenStamina');
    Origin=vect(0, 0, 0);
    
    pawn_InvManager=Animus_InventoryManager(InvManager);
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
	AimNode.bForceAimDir = true; //forces centercenter
    
    /* Derive the Attack slot from the animation tree assigned
         * to the skeletal model*/
    AttackSlot = AnimNodeSlot(SkelComp.FindAnimNode('AttackSlot'));
}

/* ========================================
 * = Item Management
 * ======================================*/
function AddDefaultInventory()
{
    // inheriting classes can add stuff to default inventory
}

public function upgradeArmor()
{
    switch(pawn_armor_state)
    {
        default: // armor of 0
            pawn_armor_state = 0;
            break;
    }
}

function bool ValidPickup(Actor Pickup)
{
    if(DroppedPickup(Pickup) != None)
    {
        return true;
    }
    
    // if we had any pickup factories, we would need to validate them here
    
    return false;
}

/*===============================
 * Save Functions
 *===============================*/

/* TODO: this function should save the player's current stats to a config
 * file when the game is saved */
function string Serialize()
{
    local JSonObject PJSonObject;
    local int i;

    // Instance the JSonObject, abort if one could not be created
    PJSonObject = new class'JSonObject';

    if (PJSonObject == None)
    {
        `Warn(Self$" could not be serialized for saving the game state.");
        return "";
    }

    // Save the location
    PJSonObject.SetFloatValue("Location_X", Location.X);
    PJSonObject.SetFloatValue("Location_Y", Location.Y);
    PJSonObject.SetFloatValue("Location_Z", Location.Z);

    // Save the rotation
    PJSonObject.SetIntValue("Rotation_Pitch", Rotation.Pitch);
    PJSonObject.SetIntValue("Rotation_Yaw", Rotation.Yaw);
    PJSonObject.SetIntValue("Rotation_Roll", Rotation.Roll);
    
    // PJSonObject.SetIntValue("IsoCamAngle", IsoCamAngle);
    // PJSonObject.SetFloatValue("CamOffsetDistance", CamOffsetDistance);
    
    //for (i=0; i<3; i++)
    //{
    //    PJSonObject.SetFloatValue("CamFixedOffset"$i, CamFixedOffset[i]);
    //}

    PJSonObject.SetIntValue("CamPitch", CamPitch);

    // Save Character stats
    for (i=0; i<2; i++)
    {
        PJSonObject.SetIntValue("pawn_health"$i, pawn_health[i]);
        PJSonObject.SetIntValue("pawn_fire_stamina"$i, pawn_fire_stamina[i]);
        PJSonObject.SetIntValue("pawn_lightning_stamina"$i, pawn_lightning_stamina[i]);
        PJSonObject.SetIntValue("pawn_wind_stamina"$i, pawn_wind_stamina[i]);
        PJSonObject.SetIntValue("pawn_level_exp"$i, pawn_level_exp[i]);
        PJSonObject.SetIntValue("pawn_weapon_exp"$i, pawn_weapon_exp[i]);
        PJSonObject.SetIntValue("pawn_fire_exp"$i, pawn_fire_exp[i]);
        PJSonObject.SetIntValue("pawn_lightning_exp"$i, pawn_lightning_exp[i]);
        PJSonObject.SetIntValue("pawn_wind_exp"$i, pawn_wind_exp[i]);
    }
    
    PJSonObject.SetIntValue("pawn_level", pawn_level);
    PJSonObject.SetIntValue("pawn_armor_state", pawn_armor_state);
    PJSonObject.SetIntValue("pawn_fire_level", pawn_fire_level);
    PJSonObject.SetIntValue("pawn_lightning_level", pawn_lightning_level);
    PJSonObject.SetIntValue("pawn_wind_level", pawn_wind_level);

    /* shouldn't need this since it is overridden in the default parameters of each class....
    for (i=0; i < 3; i++)
    {
        PJSonObject.SetIntValue("magic"$i$"_spell1_enabled", pawn_spell_info[i].spell1.enabled);
        PJSonObject.SetIntValue("magic"$i$"_spell1_range", pawn_spell_info[i].spell1.range);
        PJSonObject.SetIntValue("magic"$i$"_spell1_cost", pawn_spell_info[i].spell1.cost);
        PJSonObject.SetIntValue("magic"$i$"_spell1_core_damage", pawn_spell_info[i].spell1.core_damage);
        PJSonObject.SetIntValue("magic"$i$"_spell1_max_damage", pawn_spell_info[i].spell1.max_damage);
        //...
        //...etc
        PJSonObject.SetIntValue("magic"$i$"_spell2", pawn_spell_info[i].spell2);
        PJSonObject.SetIntValue("magic"$i$"_spell3", pawn_spell_info[i].spell3);
        PJSonObject.SetIntValue("magic"$i$"_spell4", pawn_spell_info[i].spell4);
    }
    */

    PJSonObject.SetIntValue("atk", pawn_stats.atk);
    PJSonObject.SetIntValue("def", pawn_stats.def);
    PJSonObject.SetIntValue("spd", pawn_stats.spd);
    PJSonObject.SetIntValue("crit", pawn_stats.crit);
    PJSonObject.SetIntValue("luck", pawn_stats.luck);
    PJSonObject.SetIntValue("F_atk", pawn_stats.fire_atk);
    PJSonObject.SetIntValue("W_atk", pawn_stats.wind_atk);
    PJSonObject.SetIntValue("L_atk", pawn_stats.lightning_atk);
    PJSonObject.SetIntValue("F_def", pawn_stats.fire_def);
    PJSonObject.SetIntValue("W_def", pawn_stats.wind_def);
    PJSonObject.SetIntValue("L_def", pawn_stats.lightning_def);
    PJSonObject.SetIntValue("P_res", pawn_stats.physical_res);
    PJSonObject.SetIntValue("F_res", pawn_stats.fire_res);
    PJSonObject.SetIntValue("W_res", pawn_stats.wind_res);
    PJSonObject.SetIntValue("L_res", pawn_stats.lightning_res);
    
    // TODO: save inventory (its not implemented right now so its currently a moot point)

    // If the controller is the player controller, then saved a flag to say that it should be repossessed
    //by the player when we reload the game state
    PJSonObject.SetBoolValue("IsPlayer", Animus_PlayerController(self.Controller) != none);

    // Send the encoded JSonObject
    return class'JSonObject'.static.EncodeJson(PJSonObject);
}

/* TODO: this function should load the player's current stats from a config
 * file at load time. */
function Deserialize(JsonObject Data)
{
    local Vector SavedLocation;
    local Rotator SavedRotation;
    local Animus_GameInfo AGameInfo;
    local int i;

    // Deserialize the location and set it
    SavedLocation.X = Data.GetFloatValue("Location_X");
    SavedLocation.Y = Data.GetFloatValue("Location_Y");
    SavedLocation.Z = Data.GetFloatValue("Location_Z");
    SetLocation(SavedLocation);

    // Deserialize the rotation and set it
    SavedRotation.Pitch = Data.GetIntValue("Rotation_Pitch");
    SavedRotation.Yaw = Data.GetIntValue("Rotation_Yaw");
    SavedRotation.Roll = Data.GetIntValue("Rotation_Roll");
    SetRotation(SavedRotation);

    // IsoCamAngle = Data.GetIntValue("IsoCamAngle");
    // CamOffsetDistance = Data.GetFloatValue("CamOffsetDistance");
    
    //for (i=0; i<3; i++)
    //{
    //    CamFixedOffset[i] = Data.GetFloatValue("CamFixedOffset"$i);
    //}

    CamPitch = Data.GetIntValue("CamPitch");

    // Save Character stats
    for (i=0; i<2; i++)
    {
        pawn_health[i] = Data.GetIntValue("pawn_health"$i);
        pawn_fire_stamina[i] = Data.GetIntValue("pawn_fire_stamina"$i);
        pawn_lightning_stamina[i] = Data.GetIntValue("pawn_lightning_stamina"$i);
        pawn_wind_stamina[i] = Data.GetIntValue("pawn_wind_stamina"$i);
        pawn_level_exp[i] = Data.GetIntValue("pawn_level_exp"$i);
        pawn_weapon_exp[i] = Data.GetIntValue("pawn_weapon_exp"$i);
        pawn_fire_exp[i] = Data.GetIntValue("pawn_fire_exp"$i);
        pawn_lightning_exp[i] = Data.GetIntValue("pawn_lightning_exp"$i);
        pawn_wind_exp[i] = Data.GetIntValue("pawn_wind_exp"$i);
    }

    pawn_level = Data.GetIntValue("pawn_level");
    pawn_armor_state = Data.GetIntValue("pawn_armor_state");
    pawn_fire_level = Data.GetIntValue("pawn_fire_level");
    pawn_lightning_level = Data.GetIntValue("pawn_lightning_level");
    pawn_wind_level = Data.GetIntValue("pawn_wind_level");

    /* shouldn't need this since it is overridden in the default parameters of each class....
    for (i=0; i < 3; i++)
    {
        pawn_available_magic[i].spell1 = byte(Data.GetIntValue("magic"$i$"_spell1_enabled"));
        pawn_available_magic[i].spell1 = byte(Data.GetIntValue("magic"$i$"_spell1_range"));
        pawn_available_magic[i].spell1 = byte(Data.GetIntValue("agic"$i$"_spell1_cost"));
        pawn_available_magic[i].spell1 = byte(Data.GetIntValue("magic"$i$"_spell1_core_damage"));
        pawn_available_magic[i].spell1 = byte(Data.GetIntValue("magic"$i$"_spell1_max_damage"));
        pawn_available_magic[i].spell2 = byte(Data.GetIntValue("magic"$i$"_spell2"));
        pawn_available_magic[i].spell3 = byte(Data.GetIntValue("magic"$i$"_spell3"));
        pawn_available_magic[i].spell4 = byte(Data.GetIntValue("magic"$i$"_spell4"));
    }
    */

    pawn_stats.atk = Data.GetIntValue("atk");
    pawn_stats.def = Data.GetIntValue("def");
    pawn_stats.spd = Data.GetIntValue("spd");
    pawn_stats.crit = Data.GetIntValue("crit");
    pawn_stats.luck = Data.GetIntValue("luck");
    pawn_stats.fire_atk = Data.GetIntValue("F_atk");
    pawn_stats.wind_atk = Data.GetIntValue("W_atk");
    pawn_stats.lightning_atk = Data.GetIntValue("L_atk");
    pawn_stats.fire_def = Data.GetIntValue("F_def");
    pawn_stats.wind_def = Data.GetIntValue("W_def");
    pawn_stats.lightning_def = Data.GetIntValue("L_def");
    pawn_stats.physical_res = Data.GetIntValue("P_res");
    pawn_stats.fire_res = Data.GetIntValue("F_res");
    pawn_stats.wind_res = Data.GetIntValue("W_res");
    pawn_stats.lightning_res = Data.GetIntValue("L_res");  
    
    // Deserialize if this was a player controlled pawn, if it was then tell the game info about it
    if (Data.GetBoolValue("IsPlayer"))
    {
        AGameInfo = Animus_GameInfo(self.WorldInfo.Game);

        if (AGameInfo != none)
        {
            AGameInfo.PendingPlayerPawn = self;
        }
    }
}

/* =============================================
 * = Begin Damage functions
 * =============================================*/
function int calculateDamage(EDamageSpec type, int power, optional int maxDamage=1000)
{
    local int damageOutput;
    
    // use pawn_stats to calculate damage
    switch(type)
    {
        case FIRE_DAMAGE:
            damageOutput = power + 5 * pawn_stats.fire_atk;
            break;
            
        case LIGHTNING_DAMAGE:
            damageOutput = power + 5 * pawn_stats.lightning_atk;
            break;
            
        case WIND_DAMAGE:
            damageOutput = power + 5 * pawn_stats.wind_atk;
            break;
            
        case PHYSICAL_DAMAGE:
        default:
            damageOutput = power + 5 * pawn_stats.atk;
            break;
    }
    
    /* cap off base stat damage */
    damageOutput = damageOutput > maxDamage ? maxDamage : damageOutput;
    
    // randomize damage with account for luck
    damageOutput += rand(damageOutput * 0.1 + pawn_stats.luck) - damageOutput * 0.05;
    
    // check for critical hit
    if (rand(100) < pawn_stats.crit)
        damageOutput *= 2;
         
    return damageOutput;
}

/* this code is called when this pawn takes damage */
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> damage_type_component, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
    // nullify the damage in relation to this pawn's defenses and resistances
    local class<Animus_DamageType> animus_DT;
    local int finalDamage;
    local E_ExpType earned_exp_type;
    
    animus_DT = class<Animus_DamageType>(damage_type_component);

    if (InstigatedBy == Controller)
        return;
    
    /* The way damage is handled this makes defense better early game when damage
         * is low, but resistance better late game when damage is high */
    switch (animus_DT.default.animus_damageSpec)
    {
        case FIRE_DAMAGE:
            finalDamage = Damage - (Damage * pawn_stats.fire_res / 100) - pawn_stats.fire_def;
            earned_exp_type = EXP_FIRE;
            `Log("Animus:: Damage: "@finalDamage@", Damage Type: Fire");
            break;
        case LIGHTNING_DAMAGE:
            finalDamage = Damage - (Damage * pawn_stats.lightning_res / 100) - pawn_stats.lightning_def;
            earned_exp_type = EXP_LIGHTNING;
            `Log("Animus:: Damage: "@finalDamage@", Damage Type: Lightning\n");
            break;
        case WIND_DAMAGE:
            finalDamage = Damage - (Damage * pawn_stats.wind_res / 100) - pawn_stats.wind_def;
            earned_exp_type = EXP_WIND;
            `Log("Animus:: Damage: "@finalDamage@", Damage Type: Wind\n");
            break;
        case PHYSICAL_DAMAGE:
        default:
            finalDamage = Damage - (Damage * pawn_stats.physical_res / 100) - pawn_stats.def;
            earned_exp_type = EXP_WEAPON;
            `Log("Animus:: Damage: "@finalDamage@", Damage Type: Physical\n");
    }
    
    if (finalDamage < 0)
        finalDamage = 0;
    
    `Log("Animus:: Damage Received:" $ finalDamage $ "\n");
    
    /* if damage didnt kill the player then start / reset the timer counter until the players health starts naturally regenerating */
    SetTimer(7, false, 'RegenHealth');
    
    // hack to make the player not die
    if (pawn_health[0] - finalDamage <=0 && bIsPlayer)
        finalDamage = pawn_health[0] - 1;
    
	if (pawn_health[0] - finalDamage <= 0)
	{
        `Log("Animus:: Pawn Killed\n");
        pawn_health[0] = 0;
        
        /* give experience to the pawn which killed this pawn
                 * Note that the player offers 0 experience on death so cannot
                 * result in death leveling the enemies */
        Animus_Pawn(InstigatedBy.Pawn).Award_Experience(EXP_HERO, pawn_exp_reward);
        Animus_Pawn(InstigatedBy.Pawn).Award_Experience(earned_exp_type, pawn_exp_reward);
                 
        GoToState('Dying');
	}
	else
	{
		PlaySound(SoundCue 'SoundFx.Hero_Hurt_Cue');
        pawn_health[0] -= finalDamage;
        // we should handle all the damage ourselves, this is for knockback
		Super.TakeDamage(0, InstigatedBy, HitLocation, Momentum, damage_type_component, HitInfo, DamageCauser);
	}
	
}

simulated function TakeRadiusDamage ( Controller           InstigatedBy,
                                   float               BaseDamage,
                                   float               DamageRadius,
                                   class<DamageType>  DamageType,
                                   float                Momentum,
                                   vector	              HurtOrigin,
                                   bool	              bFullDamage,
                                   Actor               DamageCauser,
                                   optional float        DamageFalloffExponent=1.f )
{
	local float		ColRadius, ColHeight;
	local float		DamageScale, Dist, ScaledDamage;
	local vector	Dir;

	GetBoundingCylinder(ColRadius, ColHeight);

	Dir	= Location - HurtOrigin;
	Dist = VSize(Dir);
	Dir	= Normal(Dir);

	if ( bFullDamage )
	{
		DamageScale = 1.f;
	}
	else
	{
		Dist = FMax(Dist - ColRadius,0.f);
		DamageScale = FClamp(1.f - Dist/DamageRadius, 0.f, 1.f);
		DamageScale = DamageScale ** DamageFalloffExponent;
	}

	if (DamageScale > 0.f)
	{
		ScaledDamage = DamageScale * BaseDamage;
		TakeDamage
		(
			ScaledDamage,
			InstigatedBy,
			Location - 0.5f * (ColHeight + ColRadius) * Dir,
			(DamageScale * Momentum * Dir),
			DamageType,,
			DamageCauser
		);
	}
}

state Dying
{
    Begin:
    
    // insert death animation
    // if main character override for gameover screen?
    Controller.Destroy();
    Destroy();
}

/* =============================================
 * = Link Emitter Logic for beams (lightning magic)
 * = (Modified from UTBeamWeapon)
 * =============================================*/
 /*
simulated function UpdateBeam()
{
	local Vector		StartTrace, EndTrace, AimDir;
	local ImpactInfo	RealImpact, NearImpact;

	// define range to use for CalcWeaponFire()
	StartTrace	= Instigator.GetWeaponStartTraceLocation();
	AimDir = Vector(GetAdjustedAim( StartTrace ));
	EndTrace	= StartTrace + AimDir * GetTraceRange();

	// Trace a shot
	RealImpact = CalcWeaponFire( StartTrace, EndTrace );
	bUsingAimingHelp = false;

	if ( (RealImpact.HitActor == None) || !RealImpact.HitActor.bProjTarget )
	{
		// console aiming help
		NearImpact = InstantAimHelp(StartTrace, EndTrace, RealImpact);

	}
	if ( NearImpact.HitActor != None )
	{
		bUsingAimingHelp = true;
		ProcessBeamHit(StartTrace, AimDir, NearImpact, DeltaTime);
		UpdateBeamEmitter(NearImpact.HitLocation, NearImpact.HitNormal, NearImpact.HitActor);
	}
	else
	{
		// Allow children to process the hit
		ProcessBeamHit(StartTrace, AimDir, RealImpact, DeltaTime);
		UpdateBeamEmitter(RealImpact.HitLocation, RealImpact.HitNormal, RealImpact.HitActor);
	}
}

simulated function AddBeamEmitter()
{
    if (BeamEmitter[CurrentFireMode] == None)
    {
        if (BeamTemplate[CurrentFireMode] != None)
        {
            BeamEmitter[CurrentFireMode] = new(Outer) class'UTParticleSystemComponent';
            BeamEmitter[CurrentFireMode].SetDepthPriorityGroup(SDPG_Foreground);
            BeamEmitter[CurrentFireMode].SetTemplate(BeamTemplate[CurrentFireMode]);
            BeamEmitter[CurrentFireMode].SetHidden(true);
            BeamEmitter[CurrentFireMode].SetTickGroup( TG_PostUpdateWork );
            BeamEmitter[CurrentFireMode].bUpdateComponentInTick = true;
            BeamEmitter[CurrentFireMode].SetIgnoreOwnerHidden(TRUE);
            SkeletalMeshComponent(Mesh).AttachComponentToSocket( BeamEmitter[CurrentFireMode],BeamSockets[CurrentFireMode] );
        }
    }
    else
    {
        BeamEmitter[CurrentFireMode].ActivateSystem();
    }
}

simulated function KillBeamEmitter()
{
	if (BeamEmitter[CurrentFireMode] != none)
	{
		BeamEmitter[CurrentFireMode].SetHidden(true);
		BeamEmitter[CurrentFireMode].DeactivateSystem();
	}
}

simulated function UpdateBeamEmitter(vector FlashLocation, vector HitNormal, actor HitActor)
{
	if (BeamEmitter[CurrentFireMode] != none)
	{
		SetBeamEmitterHidden( true );
		BeamEmitter[CurrentFireMode].SetVectorParameter(EndPointParamName,FlashLocation);
	}
}

simulated function Tick(float DeltaTime)
{
    // Retrace everything and see if there is a new LinkedTo or if something has changed.
    UpdateBeam(DeltaTime);
}
*/
/* ============================================
 * = Return Camera Target
 * ============================================*/
function vector Trace_Trajectory(out Actor HitActor, out vector HitNormal, out rotator Orient, int range, optional Actor AimTarget=None)
{
    local vector  start;
    local vector  TraceEnd;
	local rotator aimRot;
    
    // trace along the direction pointed to by the camera
    if (AimTarget == None)
    {
        `log("this should never be called... right?");
        aimRot.Yaw=Rotation.Yaw;
        aimRot.Pitch=CamPitch - 60;
        aimRot.Roll=0;

        TraceEnd = Location + (range * vector(aimRot));
        Orient = aimRot;
    }
    else
    {
        TraceEnd = AimTarget.Location;
    }
    
    // ignore the return value (the actor that is hit, world level, or none)
    HitActor = Trace(start, HitNormal, TraceEnd, Location + Origin, true, vect(1, 1, 1), , );
    
    if (HitActor == None)
	    start = TraceEnd;
        
    return start;
}
 
/* =============================================
 * = Begin Skill functions
 * =============================================*/
function Physical_Attack(optional Actor target=None)
{
    // TODO: Implement physical attack without weapon
    // used only for some enemies
}

function Magic_Fireball(optional Actor target=None)
{
    local rotator startRot;
    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    local Spell Info;
    local Actor HitActor;
    local vector HitNormal;

    `log("Fireball called");
        
    Info = pawn_spell_info[0].spell1;
    
    /* check if fireball is enabled */
    if (Info.enabled == 0)
        return;
    
    HitActor = target;

    // casting spell reduces fire spirit stamina
    if (pawn_fire_stamina[0] < Info.cost)
        return;
    else
        pawn_fire_stamina[0] -= Info.cost;
    
    // rather than normalize the vector to be able to use it, I just cast the
    // returned orientation to a unit vector
    Trace_Trajectory(HitActor, HitNormal, startRot, Info.range, target);
    
    SpawnedProjectile=Spawn(class'Proj_Fireball',self,, Location + Origin, startRot);
    
    // calculate the damage done by this fireball
    baseDamage=calculateDamage(FIRE_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Fire_DamageType');
    SpawnedProjectile.Init( Vector(startRot) );
}

function Magic_Heat_wave(optional Actor target=None)
{
	local vector start;
	local Rotator startRot, altRotation;
    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    local Spell Info;

    `log("Heat Wave called");
    
    Info = pawn_spell_info[0].spell2;
    
    /* check if heatwave is enabled */
    if (Info.enabled == 0)
        return;
    
    // casting spell reduces fire spirit stamina
    if (pawn_fire_stamina[0] < Info.cost)
        return;
    else
        pawn_fire_stamina[0] -= Info.cost;
    
    // shoot straight at given height
	 startRot = Rotation;  
    
    // shoot in the direction pointed to by the camera
    //startRot.Yaw=Rotation.Yaw;
    //startRot.Pitch=CamPitch - 60;
    //startRot.Roll=0;
    
	start = Location;
	
    altRotation=startRot;
    SpawnedProjectile=Spawn(class'Proj_HeatWave',self,, start, altRotation);
    
    // calculate the damage done by this heat wave
    baseDamage=calculateDamage(FIRE_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Fire_DamageType');
    SpawnedProjectile.Init( Vector(startRot) );
}

function Magic_Firestorm(optional Actor target=None)
{    
	local vector start;
    local rotator startRot;

    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    
    local Actor HitActor;
    local vector HitNormal;
    local Spell Info;

    `log("Firestorm called");
    
    Info = pawn_spell_info[0].spell3;
    
    /* check if firestorm is enabled */
    if (Info.enabled == 0)
        return;
    
    // casting spell reduces fire spirit stamina
    if (pawn_fire_stamina[0] < Info.cost)
        return;
    else
        pawn_fire_stamina[0] -= Info.cost;
    
    start = Trace_Trajectory(HitActor, HitNormal, startRot, Info.range, target);
	
    SpawnedProjectile=Spawn(class'Proj_FireStorm',self,, start, rot(0, 0, 0) );
    
    // calculate the damage done by this fireball with the max damage of 300
    baseDamage=calculateDamage(FIRE_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Fire_DamageType');
    SpawnedProjectile.Init( vect(0, 0, 0) );
}

function Magic_Lightning_bolt(optional Actor target=None)
{
	local vector start;
	local Rotator aimRot;
    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    
    local Actor HitActor;
    local vector HitNormal;
    local vector TraceEnd;
    local Spell Info;

    `log("Lightningbolt called");
    
    Info = pawn_spell_info[1].spell1;

    /* check if lightning bolt is enabled */
    if (Info.enabled == 0)
        return;
    
    // casting spell reduces fire spirit stamina
    if (pawn_lightning_stamina[0] < Info.cost)
        return;
    else
        pawn_lightning_stamina[0] -= Info.cost;
    
    // trace along the direction pointed to by the camera
    aimRot.Yaw=Rotation.Yaw;
    aimRot.Pitch=CamPitch - 60;
    aimRot.Roll=0;

    TraceEnd = Location + (Info.range * vector(aimRot));
    
    // ignore the return value (the actor that is hit, world level, or none)
    HitActor = Trace(start, HitNormal, TraceEnd, Location + Origin, true, vect(5, 5, 5), , );
    
    if (HitActor == None)
	    start = TraceEnd;

    // play fire animation??
    
    // add beam emitter
    //AddBeamEmitter();
    // play ambient sound
    // SoundCue'spellspackage.Lightning.LightningBolt_Cue'
    
    // add timer to kill beam emitter after fixed amount of time
    // during timer process damage?

    SpawnedProjectile=Spawn(class'Proj_LightningBolt',self,, Location + Origin, rot(0, 0, 0) );
    
    // calculate the damage done by this lightning bolt
    baseDamage=calculateDamage(LIGHTNING_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Lightning_DamageType');
    SpawnedProjectile.Init( vect(0, 0, 0) );

}

// TODO: implement
function Magic_Chain_lightning(optional Actor target=None)
{
    local Spell Info;

    `log("Chain lightning called");
    
    Info = pawn_spell_info[1].spell2;

    /* check if chain lightning is enabled */
    if (Info.enabled == 0)
        return;
}

// TODO: implement
function Magic_Storm(optional Actor target=None)
{
    local Spell Info;

    `log("Storm called");
    
    Info = pawn_spell_info[1].spell3;

    /* check if storm is enabled */
    if (Info.enabled == 0)
        return;
}

function Magic_Breeze(optional Actor target=None)
{
	local vector start;
	local Rotator startRot, altRotation;
    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    local Spell Info;

    `Log("Breeze Called");

    Info = pawn_spell_info[2].spell1;
    
    /* check if breeze is enabled */
    if (Info.enabled == 0)
        return;
    
    // casting spell reduces fire spirit stamina
    if (pawn_wind_stamina[0] < Info.cost)
        return;
    else
        pawn_wind_stamina[0] -= Info.cost;

    // shoot straight at given height
	 startRot = Rotation;  
    
    // shoot in the direction pointed to by the camera
    //startRot.Yaw=Rotation.Yaw;
    //startRot.Pitch=CamPitch - 60;
    //startRot.Roll=0;
    
	start = Location;
    start.z = 0;
	
    altRotation=startRot;
        
    SpawnedProjectile=Spawn(class'Proj_Breeze',self,, start, altRotation );
    
    // breeze does no damage, but heals the caster while they are within the radius of the heal
    baseDamage=calculateDamage(WIND_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Wind_DamageType');
    SpawnedProjectile.Init( Vector(startRot) );
}

// TODO: Implement
function Magic_Cutting_wind(optional Actor target=None)
{
    local Spell Info;

    `log("Cutting wind called");
    
    Info = pawn_spell_info[2].spell2;

    /* check if cutting wind is enabled */
    if (Info.enabled == 0)
        return;
}

// TODO: Implement
function Magic_Tail_wind(optional Actor target=None)
{
    local Spell Info;

    `log("Tail wind called");
    
    Info = pawn_spell_info[2].spell3;

    /* check if tail wind is enabled */
    if (Info.enabled == 0)
        return;
}

function Magic_Tornado(optional Actor target=None)
{
	local vector start;
	local Rotator aimRot;
    local int baseDamage;
    local Magic_Projectile spawnedProjectile;
    
    local Actor HitActor;
    local vector HitNormal;
    local Spell Info;

    `Log("Tornado Called");

    Info = pawn_spell_info[2].spell4;

    /* check if tornado is enabled */
    if (Info.enabled == 0)
        return;
    
    // casting spell reduces fire spirit stamina
    if (pawn_wind_stamina[0] < Info.cost)
        return;
    else
        pawn_wind_stamina[0] -= Info.cost;

    start = Trace_Trajectory(HitActor, HitNormal, aimRot, Info.range, target);
    start.z = 0;

    SpawnedProjectile=Spawn(class'Proj_Tornado',self,, start, rot(0, 0, 0) );
    
    // tornado hurts all enemies within the range of its hit area (more damage closer to center)
    baseDamage=calculateDamage(WIND_DAMAGE, Info.core_damage, Info.max_damage);
    
    SpawnedProjectile.preInit(baseDamage, class'Wind_DamageType');
    SpawnedProjectile.Init( vect(0, 0, 0) );
}

/*===============================
 * Stat and Experience Functions
 *===============================*/
 
function adjustHeroStats()
{
    pawn_stats.def += 1;
    pawn_stats.fire_def += 1;
    if (pawn_level > 10)
        pawn_stats.lightning_def += 1;
    if (pawn_level > 40)
        pawn_stats.wind_def += 1;
        
    pawn_stats.spd += 1;
    
    /* Critical is a percent chance to deal double damage.
         * Luck is a percent chance to half damage dealt to you.
         * As such they are not increased very frequently */
    if (pawn_level > 20)
    {
        if (pawn_level % 5 == 0)
            pawn_stats.crit += 1;
        if (pawn_level % 5 == 4)
            pawn_stats.luck += 1;
    }
    
    /* inrease maximum health */
    pawn_health[1] += pawn_level * 10;
}

function adjustWeaponStats()
{
    pawn_stats.atk += 1;

    /* Resistance is not raised very often or very much
         * it is a stat reserved mainly for armor due to its 
         * large effect on damage late game*/
    if (pawn_weapon_level > 20 && pawn_weapon_level % 5 == 1)
        pawn_stats.physical_res += 1;
}

function adjustFireStats()
{
    pawn_stats.fire_atk += 1;
    
    /* Resistance is not raised very often or very much
         * it is a stat reserved mainly for armor due to its 
         * large effect on damage late game*/
    if (pawn_fire_level > 20 && pawn_fire_level % 5 == 2)
        pawn_stats.fire_res += 1;
        
    /* increase maximum fire stamina */
    pawn_fire_stamina[1] += pawn_fire_level * 2;
    
    /* enable spells if conditions to unlock them are met */
    if (pawn_fire_level >= pawn_spell_info[0].spell1.level_unlock &&
        pawn_spell_info[0].spell1.level_unlock != 0)
        pawn_spell_info[0].spell1.enabled = 1;

    if (pawn_fire_level >= pawn_spell_info[0].spell2.level_unlock &&
        pawn_spell_info[0].spell2.level_unlock != 0)
        pawn_spell_info[0].spell2.enabled = 1;

    if (pawn_fire_level >= pawn_spell_info[0].spell3.level_unlock &&
        pawn_spell_info[0].spell3.level_unlock != 0)
        pawn_spell_info[0].spell3.enabled = 1;
}

function adjustLightningStats()
{
    pawn_stats.lightning_atk += 1;
    
    /* Resistance is not raised very often or very much
         * it is a stat reserved mainly for armor due to its 
         * large effect on damage late game*/
    if (pawn_lightning_level > 20 && pawn_lightning_level % 5 == 3)
        pawn_stats.lightning_res += 1;

    /* increase maximum lightning stamina */
    pawn_lightning_stamina[1] += pawn_lightning_level * 2;
    
    /* enable spells if conditions to unlock them are met */
    if (pawn_lightning_level >= pawn_spell_info[1].spell1.level_unlock &&
        pawn_spell_info[1].spell1.level_unlock != 0)
        pawn_spell_info[1].spell1.enabled = 1;

    if (pawn_lightning_level >= pawn_spell_info[1].spell2.level_unlock &&
        pawn_spell_info[1].spell2.level_unlock != 0)
        pawn_spell_info[1].spell2.enabled = 1;

    if (pawn_lightning_level >= pawn_spell_info[1].spell3.level_unlock &&
        pawn_spell_info[1].spell3.level_unlock != 0)
        pawn_spell_info[1].spell3.enabled = 1;
}

function adjustWindStats()
{
    pawn_stats.wind_atk += 1;
    
    /* Resistance is not raised very often or very much
         * it is a stat reserved mainly for armor due to its 
         * large effect on damage late game*/
    if (pawn_wind_level > 20 && pawn_wind_level % 5 == 4)
        pawn_stats.wind_res += 1;
        
    /* increase maximum wind stamina */
    pawn_wind_stamina[1] += pawn_wind_level * 2;
    
    /* enable spells if conditions to unlock them are met */
    if (pawn_wind_level >= pawn_spell_info[2].spell1.level_unlock &&
        pawn_spell_info[2].spell1.level_unlock != 0)
        pawn_spell_info[2].spell1.enabled = 1;

    if (pawn_wind_level >= pawn_spell_info[2].spell2.level_unlock &&
        pawn_spell_info[2].spell2.level_unlock != 0)
        pawn_spell_info[2].spell2.enabled = 1;

    if (pawn_wind_level >= pawn_spell_info[2].spell3.level_unlock &&
        pawn_spell_info[2].spell3.level_unlock != 0)
        pawn_spell_info[2].spell3.enabled = 1;

    if (pawn_wind_level >= pawn_spell_info[2].spell4.level_unlock &&
        pawn_spell_info[2].spell4.level_unlock != 0)
        pawn_spell_info[2].spell4.enabled = 1;

}

/* generate stats for pawn given the current levels
 * This is used for enemy spawning */
function generateStats()
{
    /* must override to use */
}

function Award_Experience(E_ExpType type, int amount)
{
    switch(type)
    {
        case EXP_HERO:
            pawn_level_exp[0] += amount;
            if (pawn_level_exp[0] >= pawn_level_exp[1])
            {
                /* reset experience to zero on level up
                                 * extra experience carries over to the next level */
                pawn_level_exp[0] -= pawn_level_exp[1];
                pawn_level += 1;
                
                /* increase the amount of experience needed for the next level 
                                 * by a portion of the current max (exponential increase)*/
                pawn_level_exp[1] += pawn_level_exp[1]*0.1;
                
                adjustHeroStats();
            }
        break;
        case EXP_WEAPON:
            pawn_weapon_exp[0] += amount;
            if (pawn_weapon_exp[0] >= pawn_weapon_exp[1])
            {
                /* reset experience to zero on level up
                                 * extra experience carries over to the next level */
                pawn_weapon_exp[0] -= pawn_weapon_exp[1];
                pawn_weapon_level += 1;
                
                /* increase the amount of experience needed for the next level 
                                 * by a portion of the current max (exponential increase)*/
                pawn_weapon_exp[1] += pawn_weapon_exp[1]*0.1;
                
                adjustWeaponStats();
            }
        break;
        case EXP_FIRE:
            pawn_fire_exp[0] += amount;
            if (pawn_fire_exp[0] >= pawn_fire_exp[1])
            {    
                /* reset experience to zero on level up
                                 * extra experience carries over to the next level */
                pawn_fire_exp[0] -= pawn_fire_exp[1];
                pawn_fire_level += 1;
                
                /* increase the amount of experience needed for the next level 
                                 * by a portion of the current max (exponential increase)*/
                pawn_fire_exp[1] += pawn_fire_exp[1]*0.1;
                
                adjustFireStats();
            }
        break;
        case EXP_LIGHTNING:
            pawn_lightning_exp[0] += amount;
            if (pawn_lightning_exp[0] >= pawn_lightning_exp[1])
            {
                /* reset experience to zero on level up
                                 * extra experience carries over to the next level */
                pawn_lightning_exp[0] -= pawn_lightning_exp[1];
                pawn_lightning_level += 1;
                
                /* increase the amount of experience needed for the next level 
                                 * by a portion of the current max (exponential increase)*/
                pawn_lightning_exp[1] += pawn_lightning_exp[1]*0.1;
                
                adjustLightningStats();
            }
        break;
        case EXP_WIND:
            pawn_wind_exp[0] += amount;
            if (pawn_wind_exp[0] >= pawn_wind_exp[1])
            {
                /* reset experience to zero on level up
                                 * extra experience carries over to the next level */
                pawn_wind_exp[0] -= pawn_wind_exp[1];
                pawn_wind_level += 1;
                
                /* increase the amount of experience needed for the next level 
                                 * by a portion of the current max (exponential increase)*/
                pawn_wind_exp[1] += pawn_wind_exp[1]*0.1;
                
                adjustWindStats();
            }
        break;
        default:
            `Log("Trying to award unknown experience\n");
        break;
    }
}

defaultproperties
{
    // Points to your custom AIController class - as the default value
    // will probably never be used as the player will always control this player
    ControllerClass=class'Animus.Animus_AllyController'
    InventoryManagerClass=class'Animus.Animus_InventoryManager'

    pawn_name=""
    
    /* This needs to be loaded from save */
    pawn_level=1
    pawn_level_exp[0]=0
    pawn_level_exp[1]=100
    pawn_armor_state=0
    pawn_weapon_exp[0]=0
    pawn_weapon_exp[1]=100
    pawn_fire_level=1
    pawn_fire_exp[0]=0
    pawn_fire_exp[1]=100
    pawn_lightning_level=1
    pawn_lightning_exp[0]=0
    pawn_lightning_exp[1]=100
    pawn_wind_level=1
    pawn_wind_exp[0]=0
    pawn_wind_exp[1]=100
    
    pawn_exp_reward=0
    pawn_regen_rate=3
    pawn_health_regen=0
    pawn_stamina_regen=2
    
    /* calculate pawn max health/stamina */
    pawn_health[1]=100 + pawn_level * 10;
    pawn_fire_stamina[1]=100 + (pawn_fire_level * 20);
    pawn_lightning_stamina[1]=100 + (pawn_lightning_level * 20);
    pawn_wind_stamina[1]=100 + (pawn_wind_level * 20);

    /* This needs to be loaded from save */
    pawn_health[0]=100 + pawn_level * 10;
    pawn_fire_stamina[0]=100 + (pawn_fire_level * 20);
    pawn_lightning_stamina[0]=100 + (pawn_lightning_level * 20);
    pawn_wind_stamina[0]=100 + (pawn_wind_level * 20);

    /* Calculate Default Stats for spells (but don't enable them)
     *  enabled=0
     *  range=0
     *  cost=0
     *  core_damage=0
     *  max_damage=0
     *  level_unlock=0  */
    pawn_spell_info(0)={(
                        spell1=(enabled=0,range=1500,cost=15,core_damage=30,max_damage=600,level_unlock=1), // Fireball
                        spell2=(enabled=0,range=1000,cost=25,core_damage=30,max_damage=600,level_unlock=3), // Heat Wave
                        spell3=(enabled=0,range=400,cost=30,core_damage=30,max_damage=600,level_unlock=5),   // Fire Storm
                        spell4=(enabled=0,range=0,cost=0,core_damage=0,max_damage=0,level_unlock=0),       // N/A
                        can_use=0
                       )}
    pawn_spell_info(1)={(
                        spell1=(enabled=0,range=5000,cost=3,core_damage=30,max_damage=600,level_unlock=1),  // Lightning Bolt
                        spell2=(enabled=0,range=4500,cost=3,core_damage=30,max_damage=600,level_unlock=5),  // Chain Lightning
                        spell3=(enabled=0,range=400,cost=3,core_damage=30,max_damage=600,level_unlock=10),   // Storm
                        spell4=(enabled=0,range=0,cost=0,core_damage=0,max_damage=0,level_unlock=0),       // N/A
                        can_use=0
                       )}
    pawn_spell_info(2)={(
                        spell1=(enabled=0,range=1500,cost=3,core_damage=30,max_damage=600,level_unlock=1),  // Breeze
                        spell2=(enabled=0,range=1000,cost=3,core_damage=30,max_damage=600,level_unlock=10),  // Cutting Wind
                        spell3=(enabled=0,range=400,cost=3,core_damage=30,max_damage=600,level_unlock=15),   // Tail Wind
                        spell4=(enabled=0,range=400,cost=3,core_damage=30,max_damage=600,level_unlock=20),   // Torndao
                        can_use=0
                       )}
    
    // default collision box for pawn
    Begin Object Class=CylinderComponent Name=DefaultCylinderComp
        CollisionRadius=32
        CollisionHeight=48
        CollideActors=true        
        BlockActors=false
    End Object
    
    Components.Add( DefaultCylinderComp )
    CollisionComponent=DefaultCylinderComp     
    
    bJumpCapable=true
    bCanJump=true
    bDontPossess=false // this should be default but lets just make sure
    bCollideActors=true
    bBlockActors=true
    bCanBeDamaged=true
    bIsPlayer=false
    
    GroundSpeed=300.0 //Making the bot slower than the player

    MaxLeanRoll = 0 // stop the leaning when the pawn turns
    
    SpawnSound=None
	TeleportSound=None
    ArmorHitSound=None
    
    bAlwaysRelevant=true
}