from sqlalchemy.orm import Session
from . import models, schemas
import numpy as np

def get_movie(db: Session, movie_id: int):
    return db.query(models.Movies).filter(models.Movies.id == movie_id).first()

def get_movies(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Movies).offset(skip).limit(limit).all()

def create_movie(db: Session, movie: schemas.MovieCreate):
    db_movie = models.Movies(title = movie.title, 
                             director = movie.director,release_year = movie.release_year)
    db.add(db_movie)
    db.commit()
    db.refresh(db_movie)
    return db_movie

def update_movie(db: Session, movie_id: int, movie: schemas.MovieUpdate):
    db_movie = db.query(models.Movies).filter(models.Movies.id == movie_id).first()
    if db_movie:
        db_movie.title = movie.title
        db_movie.director = movie.director
        db_movie.release_year = movie.release_year
        db.commit()
        db.refresh(db_movie)
    return db_movie

def delete_movie(db: Session, movie_id: int):
    db_movie = db.query(models.Movies).filter(models.Movies.id == movie_id).first()
    if db_movie:
        db.delete(db_movie)
        db.commit()
        return True
    return False

def get_reviews(db: Session, skip: int = 0, limit: int = 100):
    return db.query(models.Review).offset(skip).limit(limit).all()

def get_review_by_movie(db: Session, movie_id: int):
    return db.query(models.Review).filter(models.Review.movie_id == movie_id).all()

def create_review(db: Session, review: schemas.ReviewCreate, movie_id: int):
    db_review = models.Review(review_comment = review.review_comment , movie_id=movie_id,
                            rating = review.rating)
    db.add(db_review)
    db.commit()
    db.refresh(db_review)
    return db_review

def update_review(db: Session, review_id: int, review: schemas.ReviewUpdate):
    db_review = db.query(models.Review).filter(models.Review.id == review_id).first()
    if db_review:
        db_review.review_comment = review.review_comment
        db_review.rating = review.rating
        db.commit()
        db.refresh(db_review)
    return db_review

def delete_review(db: Session, review_id: int):
    db_movie = db.query(models.Review).filter(models.Review.id == review_id).first()
    if db_movie:
        db.delete(db_movie)
        db.commit()
        return True
    return False

def get_average(db: Session, movie_id: int):
    reviews = db.query(models.Review).filter(models.Review.movie_id == movie_id).all()
    if not len(reviews):
        return None
    out = []
    for review in reviews:
        out.append(review.rating)
    return {'movie':get_movie(db=db,movie_id=movie_id).title,
            'rating_average':np.mean(out)}
