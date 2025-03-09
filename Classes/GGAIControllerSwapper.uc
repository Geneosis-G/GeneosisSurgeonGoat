class GGAIControllerSwapper extends GGAIController;

var float mDestinationOffset;
var kActorSpawnable destActor;
var float totalTime;
var bool isArrived;

var float targetRadius;
var float mDetectionRadius;

var float oldStandUpDelay;
var float oldTimesKnockedByGoatStayDownLimit;
var array< ProtectInfo > oldProtectItems;

var SurgeonGoat myMut;
var GGNpc previousBody;

/**
 * Cache the NPC and mOriginalPosition
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local ProtectInfo destination;

	super.Possess(inPawn, bVehicleTransition);

	if(mMyPawn == none)
		return;
	//WorldInfo.Game.Broadcast(self, self @ "possess" @ mMyPawn);
	FindSurgeonGoat();

	oldStandUpDelay=mMyPawn.mStandUpDelay;
	oldTimesKnockedByGoatStayDownLimit=mMyPawn.mTimesKnockedByGoatStayDownLimit;

	mMyPawn.mStandUpDelay=3.0f;
	mMyPawn.mTimesKnockedByGoat=0.f;
	mMyPawn.mTimesKnockedByGoatStayDownLimit=1000000.f;

	mMyPawn.mProtectItems.Length=0;
	SpawnDestActor();
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " destActor=" $ destActor);
	destActor.SetLocation(mMyPawn.Location);

	oldProtectItems=mMyPawn.mProtectItems;
	destination.ProtectItem = mMyPawn;
	destination.ProtectRadius = 1000000.f;
	mMyPawn.mProtectItems.AddItem(destination);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mMyPawn.mProtectItems[0].ProtectItem=" $ mMyPawn.mProtectItems[0].ProtectItem);
	StandUp();
	FindBestState();
}

event UnPossess()
{
	if(mMyPawn != none)
	{
		mMyPawn.mStandUpDelay=oldStandUpDelay;
		mMyPawn.mTimesKnockedByGoatStayDownLimit=oldTimesKnockedByGoatStayDownLimit;
		mMyPawn.mProtectItems=oldProtectItems;
	}

	if(destActor != none)
	{
		destActor.ShutDown();
		destActor.Destroy();
		destActor = none;
	}
	super.UnPossess();
}

function SpawnDestActor()
{
	if(destActor == none || destActor.bPendingDelete)
	{
		destActor = Spawn(class'kActorSpawnable', mMyPawn,,,,,true);
		destActor.SetHidden(true);
		destActor.SetPhysics(PHYS_None);
		destActor.CollisionComponent=none;
	}
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

event Tick( float deltaTime )
{
	if(mMyPawn == none)//Handle being taken out of the pawn
	{
		return;
	}

	Super.Tick( deltaTime );
	//Fix dest actor is none
	SpawnDestActor();
	// Fix dead attacked pawns
	if( mPawnToAttack != none )
	{
		if( mPawnToAttack.bPendingDelete )
		{
			mPawnToAttack = none;
		}
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " state=" $ mCurrentState);
	if(!mMyPawn.mIsRagdoll)
	{
		//Fix NPC with no collisions
		if(mMyPawn.CollisionComponent == none)
		{
			mMyPawn.CollisionComponent = mMyPawn.Mesh;
		}

		//Fix NPC rotation
		UnlockDesiredRotation();
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " attack " $ mPawnToAttack);
		if(mPawnToAttack != none)
		{
			Pawn.SetDesiredRotation( rotator( Normal2D( mPawnToAttack.Location - Pawn.Location ) ) );
			mMyPawn.LockDesiredRotation( true );
		}
		else
		{
			if(IsZero(mMyPawn.Velocity))
			{
				if(isArrived)
				{
					StartRandomMovement();
				}
				else if(!IsTimerActive( NameOf( StartRandomMovement ) ))
				{
					SetTimer(RandRange(1.0f, 10.0f), false, nameof( StartRandomMovement ) );
				}
			}
			else
			{
				if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
				{
					mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );
				}
			}
		}
		FindBestState();
		// if waited too long to before reaching some place or some item, abandon
		totalTime = totalTime + deltaTime;
		if(totalTime > 11.f)
		{
			totalTime=0.f;
			mMyPawn.SetRagdoll(true);
			EndAttack();
		}
	}
	else
	{
		//Fix NPC not standing up
		if(!IsTimerActive( NameOf( StandUp ) ))
		{
			StartStandUpTimer();
		}

		//Make swapper swim
		if(mMyPawn.mInWater)
		{
			//TODO
		}
	}
}

function FindBestState()
{
	if(mPawnToAttack != none)
	{
		if(!IsValidEnemy(mPawnToAttack) || !PawnInRange(mPawnToAttack))
		{
			EndAttack();
		}
		else if(mCurrentState == '')
		{
			GotoState( 'ChasePawn' );
		}
	}
	else if(mCurrentState != 'RandomMovement')
	{
		GotoState( 'RandomMovement' );
	}
}

function StartRandomMovement()
{
	local vector dest;
	local int OffsetX;
	local int OffsetY;

	if(mPawnToAttack != none || mMyPawn.mIsRagdoll)
	{
		return;
	}
	totalTime=-10.f;
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " start random movement");

	OffsetX = Rand(1000)-500;
	OffsetY = Rand(1000)-500;

	dest.X = mMyPawn.Location.X + OffsetX;
	dest.Y = mMyPawn.Location.Y + OffsetY;
	dest.Z = mMyPawn.Location.Z;

	destActor.SetLocation(dest);
	isArrived=false;
	//mMyPawn.SetDesiredRotation(rotator(Normal(dest -  mMyPawn.Location)));

}

//All work done in EnemyNearProtectItem()
function CheckVisibilityOfGoats();
function CheckVisibilityOfEnemies();
event SeePlayer( Pawn Seen );
event SeeMonster( Pawn Seen );

/**
 * Helper function to determine if the last seen goat is near a given protect item
 * @param  protectInformation - The protectInfo to check against
 * @return true / false depending on if the goat is near or not
 */
function bool EnemyNearProtectItem( ProtectInfo protectInformation, out GGPawn enemyNear )
{
	local GGNpc tmpNPC;
	local array<GGNpc> visibleNPCs;
	local int size;

	foreach VisibleCollidingActors(class'GGNpc', tmpNPC, mDetectionRadius, mMyPawn.Location)
	{
		if(tmpNPC != mMyPawn)
		{
			visibleNPCs.AddItem(tmpNPC);
		}
	}

	size=visibleNPCs.Length;
	if(size > 0)
	{
		enemyNear=visibleNPCs[Rand(size)];
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " EnemyNearProtectItem=" $ enemyNear);
	return (enemyNear != none);
}

function StartProtectingItem( ProtectInfo protectInformation, GGPawn threat )
{
	local float h;

	StopAllScheduledMovement();
	totalTime=0.f;

	mCurrentlyProtecting = protectInformation;

	mPawnToAttack = threat;
	mPawnToAttack.GetBoundingCylinder(targetRadius, h);

	StartLookAt( threat, 5.0f );

	GotoState( 'ChasePawn' );
}

function AttackPawn()
{
	previousBody=mMyPawn;
	myMut.SwapBrains(mMyPawn, GGNpc(mPawnToAttack));
	EndAttack();
	FindBestState();
}

function StartAttack( Pawn pawnToAttack )
{
	AttackPawn();
}

event PawnFalling();//do NOT go into wait for landing state

state RandomMovement extends MasterState
{
	/**
	 * Called by APawn::moveToward when the point is unreachable
	 * due to obstruction or height differences.
	 */
	event MoveUnreachable( vector AttemptedDest, Actor AttemptedTarget )
	{
		if( AttemptedDest == mOriginalPosition )
		{
			if( mMyPawn.IsDefaultAnimationRestingOnSomething() )
			{
			    mMyPawn.mDefaultAnimationInfo =	mMyPawn.mIdleAnimationInfo;
			}

			mOriginalPosition = mMyPawn.Location;
			mMyPawn.ZeroMovementVariables();

			StartRandomMovement();
		}
	}
Begin:
	mMyPawn.ZeroMovementVariables();
	while(mPawnToAttack == none)
	{
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " STATE OK!!!");
		if(VSize2D(destActor.Location - mMyPawn.Location) > mDestinationOffset)
		{
			MoveToward (destActor);
		}
		else
		{
			if(!isArrived)
			{
				isArrived=true;
			}
			totalTime=0.f;
			Sleep(0.1f);
			MoveToward (mMyPawn,, mDestinationOffset);// Ugly hack to prevent "runnaway loop" error
		}
	}
	mMyPawn.ZeroMovementVariables();
}

state ChasePawn extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );

	while( VSize( mMyPawn.Location - mPawnToAttack.Location ) - targetRadius > mMyPawn.mAttackRange || !ReadyToAttack() )
	{
		if( mPawnToAttack == none )
		{
			ReturnToOriginalPosition();
			break;
		}

		MoveToward( mPawnToAttack,, mDestinationOffset );
	}

	FinishRotation();
	GotoState( 'Attack' );
}

state Attack extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	Focus = mPawnToAttack;

	StartAttack( mPawnToAttack );
	FinishRotation();
}

/**
 * Helper function to determine if our pawn is close to a protect item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_ProctectInformation - The info about the protect item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearProtectItem( PathNode currentlyAtNode, out ProtectInfo out_ProctectInformation )
{
	out_ProctectInformation=mMyPawn.mProtectItems[0];
	return true;
}

function bool IsValidEnemy( Pawn newEnemy )
{
	return (GGNpc(newEnemy) != none && newEnemy != previousBody);
}

function ResumeDefaultAction()
{
	super.ResumeDefaultAction();
	FindBestState();
}

function ReturnToOriginalPosition()
{
	FindBestState();
}

function DelayedGoToProtect()
{
	UnlockDesiredRotation();
	FindBestState();
}

/**
 * Try to figure out what we want to do after we have stand up
 */
function DeterminWhatToDoAfterStandup()
{
	FindBestState();
}

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	local GGPawn gpawn;

	gpawn = GGPawn( ragdolledActor );

	if( ragdolledActor == mMyPawn && isRagdoll )
	{
		if( IsTimerActive( NameOf( StopPointing ) ) )
		{
			StopPointing();
		}

		if( IsTimerActive( NameOf( StopLookAt ) ) )
		{
			StopLookAt();
		}

		if( mCurrentState == 'ProtectItem' )
		{
			ClearTimer( nameof( AttackPawn ) );
			ClearTimer( nameof( DelayedGoToProtect ) );
		}
		StopAllScheduledMovement();
		StartStandUpTimer();
		UnlockDesiredRotation();
	}

	if( gpawn != none)
	{
		if( gpawn == mLookAtActor )
		{
			StopLookAt();
		}
	}
}

function bool GoatCarryingDangerItem();
function bool PawnUsesScriptedRoute();
function StartInteractingWith( InteractionInfo intertactionInfo );
function OnTrickMade( GGTrickBase trickMade );
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum );
function OnKismetActivated( SequenceAction activatedKismet );
function bool CanPawnInteract();
function OnManual( Actor manualPerformer, bool isDoingManual, bool wasSuccessful );
function OnWallRun( Actor runner, bool isWallRunning );
function OnWallJump( Actor jumper );
function ApplaudGoat();
function PointAtGoat();
function StopPointing();
function bool WantToPanicOverTrick( GGTrickBase trickMade );
function bool WantToApplaudTrick( GGTrickBase trickMade  );
function bool WantToPanicOverKismetTrick( GGSeqAct_GiveScore trickRelatedKismet );
function bool WantToApplaudKismetTrick( GGSeqAct_GiveScore trickRelatedKismet );
function bool NearInteractItem( PathNode currentlyAtNode, out InteractionInfo out_InteractionInfo );
function bool ShouldApplaud();
function bool ShouldNotice();
event GoatPickedUpDangerItem( GGGoat goat );
function Panic();
function Dance(optional bool forever);
function PawnDied(Pawn inPawn);

DefaultProperties
{
	mDetectionRadius=5000.f
	mDestinationOffset=100.f
	bIsPlayer=true

	mAttackIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mCheckProtItemsThreatIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mVisibilityCheckIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
}
