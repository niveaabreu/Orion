from sqlalchemy import Boolean, Column, ForeignKey, Integer, String,Float
from sqlalchemy.orm import relationship



from . import database

Base = database.Base
class Movies(Base):
    __tablename__ = "movies"

    id = Column(Integer, primary_key=True, index=True,autoincrement=True)
    title = Column(String, unique=True)
    director = Column(String)
    release_year = Column(Integer)

    reviews = relationship("Review", back_populates="movie", cascade="all, delete")


class Review(Base):
    __tablename__ = "reviews"

    id = Column(Integer, primary_key=True, index=True,autoincrement=True)
    movie_id = Column(Integer, ForeignKey("movies.id"))
    review_comment = Column(String)
    rating = Column(Float)

    movie = relationship("Movies", back_populates="reviews")
