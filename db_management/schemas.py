from pydantic import BaseModel

class ReviewBase(BaseModel):
    review_comment: str | None = None
    rating: float


class ReviewCreate(ReviewBase):
    pass

class ReviewUpdate(ReviewBase):
    pass

class Review(ReviewBase):
    id: int
    movie_id: int

    class Config:
        orm_mode = True


class MovieBase(BaseModel):
    title: str
    director: str
    release_year: int


class MovieCreate(MovieBase):
    pass

class MovieUpdate(MovieBase):
    pass

class MovieDelete(MovieBase):
    pass


class Movie(MovieBase):
    id: int

    class Config:
        orm_mode = True