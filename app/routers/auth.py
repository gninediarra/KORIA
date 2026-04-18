from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from app.models.token import TokenTransaction, ActionType
from app.schemas.user import UserCreate, UserOut, RegisterOut, Token, LoginRequest
from app.services.security import hash_password, verify_password, create_access_token
from app.services.blockchain import create_wallet, encrypt_private_key, award_tokens_onchain

router = APIRouter(prefix="/api/auth", tags=["auth"])

WELCOME_TOKENS = 10


@router.post("/register", response_model=RegisterOut, status_code=status.HTTP_201_CREATED)
def register(body: UserCreate, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == body.email).first():
        raise HTTPException(status_code=400, detail="Email déjà utilisé")

    # Création automatique du portefeuille blockchain
    wallet_address, private_key = create_wallet()
    encrypted_pk = encrypt_private_key(private_key)

    user = User(
        name=body.name,
        email=body.email,
        password_hash=hash_password(body.password),
        role=body.role,
        quartier=body.quartier,
        parcelle=body.parcelle,
        wallet_address=wallet_address,
        encrypted_private_key=encrypted_pk,
        eco_tokens=WELCOME_TOKENS,
    )
    db.add(user)
    db.flush()   # obtenir l'id avant le commit

    # Bonus de bienvenue — enregistrement en base
    tx = TokenTransaction(
        user_id=user.id,
        amount=WELCOME_TOKENS,
        action_type=ActionType.welcome_bonus,
        description="Bonus de bienvenue GabèsEye",
        tx_hash=award_tokens_onchain(wallet_address, WELCOME_TOKENS, "welcome_bonus"),
    )
    db.add(tx)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(body: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == body.email).first()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Compte désactivé")
    token = create_access_token({"sub": str(user.id)})
    return Token(access_token=token, user=UserOut.model_validate(user))
