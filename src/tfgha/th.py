from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional
from datetime import datetime


class User(BaseModel):
    id: int
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    age: int = Field(..., ge=0, le=120)
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.now)
    tags: List[str] = []
    profile: Optional[dict] = None



def main():
    # Valid user
    try:
        user1 = User(
            id=1,
            username="JohnDoe",
            email="john@example.com",
            age=30,
            tags=["user", "premium"],
            profile={"bio": "Hello World"}
        )
        print("\nValid user:")
        print(user1.model_dump_json(indent=2))

    except Exception as e:
        print(f"Error creating user1: {e}")

    # Invalid user (will raise validation error)
    try:
        user2 = User(
            id="invalid",  # Should be int
            username="J",  # Too short
            email="invalid-email",  # Invalid email
            age=150,  # Age too high
        )
        print(user2)
    except Exception as e:
        print("\nValidation errors:")
        print(e)


if __name__ == "__main__":
    main()
