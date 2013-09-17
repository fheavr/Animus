/*  Thanks to http://forums.epicgames.com/threads/889873-Fireball-script
 * for a lot of the base code */

class Proj_HeatWave extends Magic_Projectile;

simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

/* Override so no explosion */
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{
	local KActorFromStatic NewKActor;
	local StaticMeshComponent HitStaticMesh;

	TriggerEventClass(class'SeqEvent_HitWall', Wall);  
    
	if ( Wall.bWorldGeometry )
	{
		HitStaticMesh = StaticMeshComponent(WallComp);
	if ( (HitStaticMesh != None) && HitStaticMesh.CanBecomeDynamic() )
	{
	        NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitStaticMesh);
	        if ( NewKActor != None )
			{
				Wall = NewKActor;
			}
	}
	}
	ImpactedActor = Wall;
	if ( !Wall.bStatic && (DamageRadius == 0) )
	{
		Wall.TakeDamage( Damage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), MyDamageType,, self);
	}

}

defaultproperties
{
	ProjFlightTemplate=ParticleSystem'spellspackage.heatwave.heatwave'
	//ProjExplosionTemplate=ParticleSystem'WP_RocketLauncher.Effects.P_WP_RocketLauncher_RocketExplosion'
	//ExplosionDecal=MaterialInstanceTimeVarying'WP_RocketLauncher.Decals.MITV_WP_RocketLauncher_Impact_Decal01'
    
    // Make Projectile not a point collision
	Begin Object Class=CylinderComponent Name=CollisionOverride
		CollisionRadius=5
		CollisionHeight=5
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
	End Object
	CollisionComponent=CollisionOverride
	CylinderComponent=CollisionOverride
	Components.Add(CollisionOverride)
    
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
	//ExplosionLightClass=class'UTGame.UTRocketExplosionLight'

	bWaitForEffects=true
	bAttachExplosionToVehicles=false
    
    
}