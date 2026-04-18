from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from typing import List
from app.database import get_db
from app.models.user import User
from app.models.token import TokenTransaction, DronePriorityVote
from app.schemas.token import TokenBalance, TokenTransactionOut, VotePriorityIn, VotePriorityOut, DronePriorityResult, LeaderboardEntry
from app.services.deps import get_current_user
from app.services.blockchain import get_token_balance_onchain, spend_tokens_onchain, award_tokens_onchain
from datetime import datetime, timezone

router = APIRouter(prefix="/api/tokens", tags=["tokens"])

VOTE_COST = 20


@router.get("/balance", response_model=TokenBalance)
def get_balance(current_user: User = Depends(get_current_user)):
    onchain = None
    if current_user.wallet_address:
        onchain = get_token_balance_onchain(current_user.wallet_address)
    return TokenBalance(
        wallet_address=current_user.wallet_address,
        eco_tokens=current_user.eco_tokens,
        onchain_balance=onchain,
    )


@router.get("/transactions", response_model=List[TokenTransactionOut])
def get_transactions(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    txs = (
        db.query(TokenTransaction)
        .filter(TokenTransaction.user_id == current_user.id)
        .order_by(desc(TokenTransaction.timestamp))
        .limit(limit)
        .all()
    )
    return txs


@router.post("/vote-priority", response_model=VotePriorityOut)
def vote_drone_priority(
    body: VotePriorityIn,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if current_user.eco_tokens < body.tokens_to_spend:
        raise HTTPException(status_code=400, detail="Solde ECT insuffisant")

    now = datetime.now(timezone.utc)
    week_of = f"{now.year}-W{now.isocalendar().week:02d}"

    # Débit en base
    current_user.eco_tokens -= body.tokens_to_spend

    tx_hash = spend_tokens_onchain(
        current_user.wallet_address or "",
        body.tokens_to_spend,
        f"vote_priority:{body.zone_name}",
    )

    db.add(TokenTransaction(
        user_id=current_user.id,
        amount=-body.tokens_to_spend,
        action_type="vote_priority",
        description=f"Vote priorité drone → {body.zone_name}",
        tx_hash=tx_hash,
    ))
    db.add(DronePriorityVote(
        user_id=current_user.id,
        zone_name=body.zone_name,
        week_of=week_of,
        tokens_spent=body.tokens_to_spend,
    ))
    db.commit()
    db.refresh(current_user)

    return VotePriorityOut(
        zone_name=body.zone_name,
        week_of=week_of,
        tokens_spent=body.tokens_to_spend,
        remaining_balance=current_user.eco_tokens,
    )


@router.get("/drone-priority", response_model=List[DronePriorityResult])
def get_drone_priority(db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    now = datetime.now(timezone.utc)
    week_of = f"{now.year}-W{now.isocalendar().week:02d}"

    votes = db.query(DronePriorityVote).filter(DronePriorityVote.week_of == week_of).all()

    aggregated: dict[str, dict] = {}
    for v in votes:
        if v.zone_name not in aggregated:
            aggregated[v.zone_name] = {"zone_name": v.zone_name, "total_votes": 0, "total_tokens": 0}
        aggregated[v.zone_name]["total_votes"] += 1
        aggregated[v.zone_name]["total_tokens"] += v.tokens_spent

    return sorted(aggregated.values(), key=lambda x: x["total_tokens"], reverse=True)


@router.get("/leaderboard", response_model=List[LeaderboardEntry])
def get_leaderboard(limit: int = 10, db: Session = Depends(get_db), _: User = Depends(get_current_user)):
    users = (
        db.query(User)
        .filter(User.is_active == True)
        .order_by(desc(User.eco_tokens))
        .limit(limit)
        .all()
    )
    return [
        LeaderboardEntry(
            rank=i + 1,
            user_id=u.id,
            name=u.name,
            eco_tokens=u.eco_tokens,
            role=u.role.value,
        )
        for i, u in enumerate(users)
    ]
