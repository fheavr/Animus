/*  Abstract class to be extended by all Animus Projectiles */

class Magic_Projectile extends UTProjectile;

var() class<DamageType> primaryDamageType;
var() int primaryBaseDamage;
var() class<DamageType> secondaryDamageType;
var() int secondaryBaseDamage;
var() Animus_Pawn caster;

simulated function PostBeginPlay()
{
	// force ambient sound if not vehicle game mode
	bImportantAmbientSound = !WorldInfo.bDropDetail;
	Super.PostBeginPlay();
}

// for now secondary damage types are assumed to take 1/3 of the base damage
// with the other 2/3 allocated to the primary damage type
// if the castBy is left default then the projectile will hurt everyone
function preInit(int baseDamage, optional class<DamageType> primaryDT=None, optional class<DamageType> secondaryDT=None)
{
    caster=Animus_Pawn(Owner);
    primaryDamageType=primaryDT;
    secondaryDamageType=secondaryDT;
    if (primaryDamageType!=None && secondaryDamageType!=None)
    {
        primaryBaseDamage=baseDamage*2/3;
        secondaryBaseDamage=baseDamage/3;
    }
    else
    {
        primaryBaseDamage=baseDamage;
    }
}

simulated function ProcessTouch( Actor Other, vector HitLocation, vector HitNormal )
{
    `Log("ProcessTouch Entered\n");
    // cannot damage oneself
    if (Other==caster)
        return;

    // primary damage is affected on the hit target
    Other.TakeDamage(primaryBaseDamage, InstigatorController, HitLocation, MomentumTransfer * Normal(Velocity), primaryDamageType,, caster);
    
    //secondary damage is affected only if the damage has a second component
    if (secondaryBaseDamage!=0)
        Other.TakeDamage(secondaryBaseDamage, InstigatorController, HitLocation, MomentumTransfer * Normal(Velocity), secondaryDamageType,, caster);
}

/* TODO: make walls destructible?
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{
    // primary damage is affected on the hit target
    Wall.TakeDamage(primaryBaseDamage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), primaryDamageType,, caster);
    
    //secondary damage is affected only if the damage has a second component
    if (secondaryBaseDamage!=0)
        Wall.TakeDamage(secondaryBaseDamage, InstigatorController, Location, MomentumTransfer * Normal(Velocity), secondaryDamageType,, caster);
	Super.HitWall(HitNormal, Wall, WallComp);
}
*/

/**
 * Explode this Projectile
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	if (Damage>0 && DamageRadius>0)
	{
		if ( Role == ROLE_Authority )
			MakeNoise(1.0);
		if ( !bShuttingDown )
		{
            // we dont want the explosion causing extra damage on top of the spell
			// ProjectileHurtRadius(HitLocation, HitNormal );
		}
	}
	SpawnExplosionEffects(HitLocation, HitNormal);

	ShutDown();
}

defaultproperties
{
    // Make Projectile not a point collision
	Begin Object Class=CylinderComponent Name=CollisionParticle
		CollisionRadius=1
		CollisionHeight=1
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
	End Object
	CollisionComponent=CollisionParticle
	CylinderComponent=CollisionParticle
	Components.Add(CollisionParticle)

    bCollideActors=true
    MomentumTransfer=2
    
    primaryDamageType=None
    secondaryDamageType=None
    caster=None
    primaryBaseDamage=1
    secondaryBaseDamage=0
    Damage=1 // for HitWallCalculations at the moment
}