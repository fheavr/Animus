class Proj_LightningBolt extends Magic_Projectile;

simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

defaultproperties
{
    // Make Projectile not a point collision
	Begin Object Class=CylinderComponent Name=CollisionOverride
		CollisionRadius=1
		CollisionHeight=1
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
	End Object
	CollisionComponent=CollisionOverride
	CylinderComponent=CollisionOverride
	Components.Add(CollisionOverride)

	ProjFlightTemplate=ParticleSystem'spellspackage.Lightning.Lightning-beam'
	//ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	//ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
	DecalWidth=128.0
	DecalHeight=128.0
	speed=0.0
	MaxSpeed=0.0
	Damage=0.0
	DamageRadius=400.0
	MomentumTransfer=85000
	primaryDamageType=class'Wind_DamageType'
	LifeSpan=1.0
	AmbientSound=SoundCue'spellspackage.Lightning.LightningBolt_Cue'
	//ExplosionSound=SoundCue'A_Weapon_RocketLauncher.Cue.A_Weapon_RL_Impact_Cue'
	RotationRate=(Roll=0)
	bCollideWorld=true
	CheckRadius=420.0
	bCheckProjectileLight=true
	//ProjectileLightClass=class'UTGame.UTRocketLight'
	//ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
    
    
}