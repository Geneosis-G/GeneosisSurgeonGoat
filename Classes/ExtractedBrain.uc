class ExtractedBrain extends GGZombieBrainsPickupContent;

var SurgeonGoat myMut;

var name mOwnerName;
var string mOwnerActorName;
var class<GGAIController> contrClass;
var Actor contrOwner;

var ParticleSystem mTrailEffectTemplate;
var ParticleSystemComponent mTrailEffectPSC;

var float mTimeNotLookingForRelocate;
var bool mHasBeenSeen;
var float mLastKnownRenderTime;

//Remove problematic parent functions
function DeleteWhenNotRendered();
function bool IsBeingRendered();
function GiveHealthAndHungerToGrabbingGoat();

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();

	mLastKnownRenderTime=WorldInfo.TimeSeconds;

	mTrailEffectPSC = WorldInfo.MyEmitterPool.SpawnEmitter( mTrailEffectTemplate, Location, Rotation, self );
	mTrailEffectPSC.DeactivateSystem();
	mTrailEffectPSC.KillParticlesForced();

 	if(GGNpc(Owner) != none)
 	{
		SetBrainInfos(GGNpc(Owner));
	}

	ClearTimer('DeleteWhenNotRendered', self);
}

function SetBrainInfos(GGNpc possessedNPC)
{
	if(possessedNPC == none || possessedNPC.Controller == none)
	{
		RemoveBrain();
		return;
	}

	contrClass=class<GGAIController>(possessedNPC.Controller.class);
	contrOwner=possessedNPC.Controller.Owner;
	if(contrClass == class'GGAIControllerSwapper')
	{
		mTrailEffectPSC.ActivateSystem();
	}
}

function string GetActorName()
{
	return mOwnerActorName != ""
		?mOwnerActorName $ "'s Brain"
		:"Brain";
}

function RemoveBrain()
{
	//WorldInfo.Game.Broadcast(self, self $  " RemoveBrain");
	mTrailEffectPSC.DeactivateSystem();
	mTrailEffectPSC.KillParticlesForced();
	ShutDown();
	Destroy();
}

function SetSwapperBrain(out int swapperID)
{
	contrClass=class'GGAIControllerSwapper';
	mOwnerName=name("Swapper_" $ swapperID);
	mOwnerActorName="Swapper";
	swapperID++;
	mTrailEffectPSC.ActivateSystem();
}

simulated event Tick( float delta )
{
	super.Tick( delta );
	//Special relocation behaviour only for swapper brain
	if(contrClass != class'GGAIControllerSwapper')
		return;

	if(LastRenderTime > mLastKnownRenderTime )
	{
		mLastKnownRenderTime=LastRenderTime;
	}
	if(!mHasBeenSeen)
	{
		mHasBeenSeen = `TimeSince( LastRenderTime ) < 0.5f;
	}
	if((!mHasBeenSeen && `TimeSince( mLastKnownRenderTime ) > mTimeNotLookingForRelocate))
	{
		Relocate();
	}
}

function Relocate()
{
	FindSurgeonGoat();
	mLastKnownRenderTime = WorldInfo.TimeSeconds;
	CollisionComponent.SetRBPosition(myMut.GetRandomSpawnLocation());
}

function FindSurgeonGoat()
{
	if(myMut != none)
		return;

	foreach AllActors(class'SurgeonGoat', myMut)
	{
		break;
	}
}

DefaultProperties
{
	mTimeNotLookingForRelocate=60.f

	mTrailEffectTemplate=ParticleSystem'Zombie_Particles.Particles.Voodoo_Trail_ParticleSystem'
}