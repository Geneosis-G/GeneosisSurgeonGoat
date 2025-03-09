class SurgeonGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var SurgeonGoat myMut;

var StaticMeshComponent mHatMesh;
var ParticleSystemComponent mSurgeryPSC;
var SoundCue mSurgerySound;
var AudioComponent mAC;
var float mSurgeryTime;
var float mSurgeryRadius;

var GGNpc targetNPC;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=SurgeonGoat(owningMutator);

		mHatMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( mHatMesh, 'hairSocket' );
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ))
		{
			FindNPCForSurgery();
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed( "GBA_Special", string( newKey ) ))
		{
			EndSurgery(true);
		}
	}
}

function vector GetPawnPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

function FindNPCForSurgery()
{
	local GGNpc hitNPC, foundNPC;
	local float dist, minDist;

	if(gMe.mIsRagdoll
	|| !IsZero(gMe.Velocity))
		return;

	//Find the closed NPC to the goat
	foreach myMut.VisibleCollidingActors( class'GGNpc', hitNPC, mSurgeryRadius, gMe.Location)
	{
		dist=VSizeSq(GetPawnPosition(hitNPC)-GetPawnPosition(gMe));
		if(foundNPC == none || dist < minDist)
		{
			foundNPC = hitNPC;
			minDist = dist;
		}
	}

	//WorldInfo.Game.Broadcast(self, "Trace : " $ hitActor);
	if(foundNPC == none)
		return;
	//No surgery if no brain to implant
	if(foundNPC.Controller == none && ExtractedBrain(gMe.mGrabbedItem) == none)
		return;

	targetNPC=foundNPC;
	StartSurgery(targetNPC);
}

function StartSurgery(GGNpc surgeryNPC)
{
	if(!IsZero(surgeryNPC.mesh.GetBoneLocation('Head')))
	{
		surgeryNPC.mesh.AttachComponent(mSurgeryPSC, 'Head');
	}
	else
	{
		surgeryNPC.mesh.AttachComponent(mSurgeryPSC, 'Root');
	}
	mSurgeryPSC.ActivateSystem();

	if( mAC == none || mAC.IsPendingKill() )
	{
		mAC = gMe.CreateAudioComponent( mSurgerySound, false );
	}
	if(mAC.isPlaying())
	{
		mAC.Stop();
	}
	mAC.Play();

	gMe.SetTimer(mSurgeryTime, false, NameOf(EndSurgery), self);
}

function EndSurgery(optional bool forceEnd)
{
	gMe.ClearTimer(NameOf(EndSurgery), self);

	if(forceEnd)
	{
		mSurgeryPSC.DeactivateSystem();
		mSurgeryPSC.KillParticlesForced();
		mSurgeryPSC.DetachFromAny();
		if(mAC != none && mAC.isPlaying())
		{
			mAC.Stop();
		}
	}
	else if(targetNPC != none)
	{
		PerformSurgery();
	}
	targetNPC=none;
}

function PerformSurgery()
{
	local GGAIController oldController;

	if(targetNPC == none)
		return;

	//Remove brain if controlled
	if(targetNPC.Controller != none)
	{
		oldController=GGAIController(targetNPC.Controller);
		MakeBrainFromNPC(targetNPC);
		targetNPC.Controller.Unpossess();
		targetNPC.mAnimNodeSlot.StopAnim();
		targetNPC.mAnimNodeSlot.StopCustomAnim(0.1f);
		if(oldController != none)
		{
			oldController.Destroy();
		}
	}
	//Add brain licked if not controlled
	else
	{
		ImplantBrainToNPC(ExtractedBrain(gMe.mGrabbedItem), targetNPC);
	}
}

function MakeBrainFromNPC(GGNpc surgeryNPC)
{
	local vector spawnLocation;
	local ExtractedBrain newBrain;

	if(surgeryNPC == none
	|| GGAIController(surgeryNPC.Controller) == none)
		return;

	spawnLocation=GetPawnPosition(gMe) + 0.5f * (GetPawnPosition(surgeryNPC)-GetPawnPosition(gMe));
	newBrain=gMe.Spawn(class'ExtractedBrain', surgeryNPC,, spawnLocation,,, true);
	if(newBrain != none && !newBrain.bPendingDelete)
	{
		if(!myMut.HaveTransplantedBrain(surgeryNPC))
		{
			myMut.AddBrainOwner(surgeryNPC);
		}
		else
		{
			myMut.RestoreNPCMesh(surgeryNPC);
		}
		myMut.GetBrainOwnerNames(surgeryNPC, newBrain.mOwnerName, newBrain.mOwnerActorName);
	}
}

function ImplantBrainToNPC(ExtractedBrain newBrain, GGNpc surgeryNPC)
{
	local GGAIController newController;

	if(newBrain == none
	|| surgeryNPC == none
	|| surgeryNPC.Controller != none)
		return;

	newController=gMe.Spawn(newBrain.contrClass, newBrain.contrOwner);
	if(newController != none)
	{
		newController.Possess(surgeryNPC, false);
		newController.StandUp();
		if(surgeryNPC.mIsRagdoll)
		{
			surgeryNPC.StandUp();
		}

		myMut.SetBrainCurrentOwner(surgeryNPC, newBrain.mOwnerName);
	}

	newBrain.RemoveBrain();

	myMut.SpawnSwapperBrain();
}

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	super.OnRagdoll( ragdolledActor, isRagdoll );

	if(targetNPC != none
	&& ragdolledActor == gMe
	&& isRagdoll)
	{
		EndSurgery(true);
	}
}

defaultproperties
{
	mSurgeryTime=2.f
	mSurgeryRadius=600.f

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Goat_Zombie.Meshes.Heisengoat_Hat_01'
	End Object
	mHatMesh=StaticMeshComp1

	Begin Object class=ParticleSystemComponent Name=ParticleSystemComponent0
        Template=ParticleSystem'Zombie_Particles.Particles.Crafting_Cloud'
		bAutoActivate=true
		bResetOnDetach=true
	End Object
	mSurgeryPSC=ParticleSystemComponent0

	mSurgerySound=SoundCue'Zombie_Sounds.ZombieGameMode.Crafting_Full_Cue'
}