/*  Thanks to http://forums.epicgames.com/threads/889873-Fireball-script
 * for a lot of the base code */

class Proj_Breeze extends Magic_Projectile;

simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

defaultproperties
{
    // Make Projectile not a point collision (lets you heal while running)
	Begin Object Class=CylinderComponent Name=CollisionOverride
		CollisionRadius=5
		CollisionHeight=5
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
	End Object
	CollisionComponent=CollisionOverride
	CylinderComponent=CollisionOverride
	Components.Add(CollisionOverride)

	ProjFlightTemplate=ParticleSystem'spellspackage.Wind.HealingWind'
	//ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	//ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
	DecalWidth=128.0
	DecalHeight=128.0
	speed=0.0
	MaxSpeed=0.0
	Damage=0.0
	DamageRadius=220.0
	MomentumTransfer=85000
	primaryDamageType=class'Wind_DamageType'
	LifeSpan=1.0
	AmbientSound=SoundCue'spellspackage.Wind.Breeze'
	//ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	RotationRate=(Roll=0)
	bCollideWorld=true
	CheckRadius=42.0
	bCheckProjectileLight=true
	ProjectileLightClass=class'UTGame.UTRocketLight'
	//ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
    
    
}