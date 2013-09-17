/* Thanks to http://www.mavrikgames.com/tutorials/melee-weapons/melee-weapon-tutorial-part-1
 * and       http://forums.epicgames.com/threads/771828-Melee-Weapons/page3?highlight=melee
 * for  most of the weapon code */

class Animus_Sword extends Animus_Weapon
  dependson(Animus_DamageType);

DefaultProperties
{
    Begin Object Class=SkeletalMeshComponent Name=SwordSkeletalMeshComponent
       bCacheAnimSequenceNodes=false
       CastShadow=true
       BlockRigidBody=true
       bUpdateSkelWhenNotRendered=false
       bIgnoreControllersWhenNotRendered=true
       bUpdateKinematicBonesFromAnimation=true
       bCastDynamicShadow=true
       bOverrideAttachmentOwnerVisibility=true
       bHasPhysicsAssetInstance=true
       TickGroup=TG_PreAsyncWork
       MinDistFactorForKinematicUpdate=0.2f
       bChartDistanceFactor=true
       Translation=(Z=1)
       Rotation=(Roll=-400)
       Scale=1.f
       bAllowAmbientOcclusion=false
       bUseOnePassLightingOnTranslucency=true
       bPerBoneMotionBlur=true
       SkeletalMesh=SkeletalMesh'WeaponPackage.basicsword'
    End Object
    Components.Add(SwordSkeletalMeshComponent)
    Mesh=SwordSkeletalMeshComponent
    
    atk_time=2.4f
    hit_breadth=8192 //  65536/8 = 360/8 = 45 degrees
    hit_depth=400
    damage=50
    momentum=80000
    
    item=class'Item_Sword'
}