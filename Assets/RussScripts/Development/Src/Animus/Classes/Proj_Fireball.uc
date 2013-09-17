/*  Thanks to http://forums.epicgames.com/threads/889873-Fireball-script
 * for a lot of the base code */

class Proj_Fireball extends Magic_Projectile;

simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

simulated function ProcessTouch( Actor Other, vector HitLocation, vector HitNormal )
{
    super.ProcessTouch( Other, HitLocation, HitNormal );
    Explode( HitLocation, HitNormal);
}

defaultproperties
{
	//ProjFlightTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketTrail'
    ProjFlightTemplate=ParticleSystem'spellspackage.Fireball.fireballProjectileBackup'
	ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
	DecalWidth=128.0
	DecalHeight=128.0
	speed=1350.0
	MaxSpeed=1350.0
	Damage=100.0
	DamageRadius=220.0
	MomentumTransfer=20000
	primaryDamageType=class'Fire_DamageType'
	LifeSpan=8.0
	AmbientSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Travel_Cue'
	ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	RotationRate=(Roll=50000)
	bCollideWorld=true
	CheckRadius=42.0
	bCheckProjectileLight=true
	ProjectileLightClass=class'UTGame.UTRocketLight'
	ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
}