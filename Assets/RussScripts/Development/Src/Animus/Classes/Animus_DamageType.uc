class Animus_DamageType extends DamageType;

enum EDamageSpec
{
    PHYSICAL_DAMAGE,
    FIRE_DAMAGE,
    LIGHTNING_DAMAGE,
    WIND_DAMAGE
};

var EDamageSpec animus_damageSpec;

defaultproperties
{
    animus_damageSpec=PHYSICAL_DAMAGE
}