
import os
import json

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import (
    create_engine,
    Column,
    Integer,
    String,
    Text,
    ForeignKey,
    UniqueConstraint,
)
from sqlalchemy.orm import declarative_base, sessionmaker
from pwdlib import PasswordHash
from openai import OpenAI


app = FastAPI(title="Giftly AI API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database setup
DATABASE_URL = "sqlite:///./giftly.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False},
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

Base = declarative_base()
password_hash = PasswordHash.recommended()


# Database tables
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)


class SavedGift(Base):
    __tablename__ = "saved_gifts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id"),
        nullable=False,
        index=True,
    )
    gift_name = Column(String, nullable=False)
    gift_data = Column(Text, nullable=False)

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "gift_name",
            name="unique_saved_gift_per_user",
        ),
    )


Base.metadata.create_all(bind=engine)


# Request models
class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class GiftRequest(BaseModel):
    recipient_description: str = Field(
        min_length=5,
        max_length=3000,
    )
    recipient_name: str = "Recipient"
    occasion: str = "Any occasion"
    relationship: str = "Not specified"
    budget: str = "Not specified"
    currency: str = "INR"
    interests: list[str] = Field(default_factory=list)
    previous_gifts: list[str] = Field(default_factory=list)
    conversation_history: list[dict[str, str]] = Field(
        default_factory=list
    )
    refinement: str = ""


class SaveGiftRequest(BaseModel):
    gift_name: str = Field(min_length=1, max_length=300)
    gift_data: dict


# Health endpoints
@app.get("/")
def home():
    return {
        "message": "Giftly AI API is running successfully!"
    }


@app.get("/health")
def health_check():
    return {"status": "OK"}


# Register
@app.post("/register")
def register(data: RegisterRequest):
    name = data.name.strip()
    email = str(data.email).strip().lower()

    if not name:
        raise HTTPException(
            status_code=400,
            detail="Name is required",
        )

    if len(data.password) < 8:
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least 8 characters",
        )

    db = SessionLocal()

    try:
        existing_user = (
            db.query(User)
            .filter(User.email == email)
            .first()
        )

        if existing_user:
            raise HTTPException(
                status_code=409,
                detail="Email is already registered",
            )

        user = User(
            name=name,
            email=email,
            password=password_hash.hash(data.password),
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        return {
            "message": "Registration successful",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
            },
        }

    finally:
        db.close()


# Login
@app.post("/login")
def login(data: LoginRequest):
    email = str(data.email).strip().lower()
    db = SessionLocal()

    try:
        user = (
            db.query(User)
            .filter(User.email == email)
            .first()
        )

        if not user or not password_hash.verify(
            data.password,
            user.password,
        ):
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
            )

        return {
            "message": "Login successful",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
            },
        }

    finally:
        db.close()


# Get saved gifts for a user
@app.get("/users/{user_id}/saved-gifts")
def get_saved_gifts(user_id: int):
    db = SessionLocal()

    try:
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found",
            )

        saved = (
            db.query(SavedGift)
            .filter(SavedGift.user_id == user_id)
            .order_by(SavedGift.id.desc())
            .all()
        )

        return {
            "saved_gifts": [
                {
                    "id": item.id,
                    "gift_name": item.gift_name,
                    "gift_data": json.loads(item.gift_data),
                }
                for item in saved
            ]
        }

    finally:
        db.close()


# Save a gift
@app.post("/users/{user_id}/saved-gifts")
def save_gift(user_id: int, data: SaveGiftRequest):
    db = SessionLocal()

    try:
        user = db.query(User).filter(User.id == user_id).first()

        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found",
            )

        name = data.gift_name.strip()

        existing = (
            db.query(SavedGift)
            .filter(
                SavedGift.user_id == user_id,
                SavedGift.gift_name == name,
            )
            .first()
        )

        if existing:
            existing.gift_data = json.dumps(
                data.gift_data,
                ensure_ascii=False,
            )
            db.commit()

            return {
                "message": "Saved gift updated",
                "id": existing.id,
            }

        item = SavedGift(
            user_id=user_id,
            gift_name=name,
            gift_data=json.dumps(
                data.gift_data,
                ensure_ascii=False,
            ),
        )

        db.add(item)
        db.commit()
        db.refresh(item)

        return {
            "message": "Gift saved successfully",
            "id": item.id,
        }

    finally:
        db.close()


# Remove a saved gift
@app.delete("/users/{user_id}/saved-gifts/{gift_name}")
def delete_saved_gift(user_id: int, gift_name: str):
    db = SessionLocal()

    try:
        item = (
            db.query(SavedGift)
            .filter(
                SavedGift.user_id == user_id,
                SavedGift.gift_name == gift_name,
            )
            .first()
        )

        if not item:
            raise HTTPException(
                status_code=404,
                detail="Saved gift not found",
            )

        db.delete(item)
        db.commit()

        return {"message": "Gift removed successfully"}

    finally:
        db.close()


# AI gift recommendations
@app.post("/recommend-gifts")
def recommend_gifts(data: GiftRequest):
    api_key = os.getenv("OPENAI_API_KEY")

    if not api_key:
        raise HTTPException(
            status_code=503,
            detail=(
                "AI is not configured. "
                "Set the OPENAI_API_KEY environment variable."
            ),
        )

    history = []

    for item in data.conversation_history[-10:]:
        role = item.get("role", "")
        content = item.get("content", "")

        if role in ("user", "assistant") and content:
            history.append({
                "role": role,
                "content": content[:2000],
            })

    prompt_data = {
        "recipient_name": data.recipient_name,
        "recipient_description": data.recipient_description,
        "occasion": data.occasion,
        "relationship": data.relationship,
        "budget": data.budget,
        "currency": data.currency,
        "interests": data.interests,
        "previous_gifts_to_avoid": data.previous_gifts,
        "new_refinement_request": data.refinement,
    }

    instructions = """
You are Giftly AI, a personalized gift recommendation assistant.

Generate 5 to 8 specific gift ideas when enough suitable options exist.
Prioritize the recipient's explicitly stated interests and requested
categories. Do not include unrelated categories merely to fill the list.

Respect budget, occasion, relationship and exclusions.
Avoid all gifts listed in previous_gifts_to_avoid.
Avoid repeating ideas already suggested in conversation history.
If the recipient likes toys, suggest actual toys or toy-related gifts,
not unrelated stationery, skincare or home products.
If there are fewer than five suitable ideas, return fewer rather
than inventing irrelevant matches.

Prices are estimates, not verified live prices.
Never invent shopping links.

Return ONLY valid JSON:
{
  "gifts": [
    {
      "rank": 1,
      "name": "Specific gift name",
      "price_range": "Estimated price range",
      "reasoning": "Why this fits the recipient",
      "confidence": 0.92
    }
  ],
  "message": "A short friendly introduction"
}

Confidence must be between 0 and 1.
"""

    user_input = (
        "Recipient details:\n"
        + json.dumps(prompt_data, ensure_ascii=False)
        + "\n\nRecent conversation:\n"
        + json.dumps(history, ensure_ascii=False)
    )

    try:
        client = OpenAI(api_key=api_key)

        response = client.responses.create(
            model=os.getenv("OPENAI_MODEL", "gpt-5.4-mini"),
            instructions=instructions,
            input=user_input,
        )

        result_text = response.output_text.strip()

        if result_text.startswith("```"):
            result_text = result_text.split("\n", 1)[-1]

            if result_text.endswith("```"):
                result_text = result_text[:-3].strip()

            if result_text.startswith("json"):
                result_text = result_text[4:].strip()

        result = json.loads(result_text)

        if not isinstance(result.get("gifts"), list):
            raise ValueError("AI response did not contain a gift list")

        result["gifts"] = result["gifts"][:8]

        for index, gift in enumerate(result["gifts"], start=1):
            gift["rank"] = index

        return result

    except json.JSONDecodeError:
        raise HTTPException(
            status_code=502,
            detail="AI returned an invalid response. Please try again.",
        )

    except Exception as exc:
        print(
            f"Gift recommendation error: "
            f"{type(exc).__name__}: {exc}"
        )

        raise HTTPException(
            status_code=502,
            detail=(
                "Could not generate gift recommendations. "
                "Check the backend terminal and try again."
            ),
        )
