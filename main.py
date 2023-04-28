from fastapi import FastAPI,HTTPException,Query,Path, Depends
from fastapi.responses import HTMLResponse
import numpy as np
from typing import Annotated
from db_management import crud,models,schemas
from db_management.database import SessionLocal, engine
from sqlalchemy.orm import Session

models.Base.metadata.create_all(bind=engine)

__authors__ = ["Matheus Oliveira", "Nívea de Abreu"]

description = """
Orion is a REST API for ORM management of MySQL DB  🚀

## Movies

You can see and create new movies in the Database.

## Reviews

You will be able to:

* **Create review** 
* *Update a review** 
* *List reviews** 
"""


app = FastAPI(title="Orion",
    description=description,
    version="0.0.1")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/",status_code=200,tags=["index"],summary="Página de Index")
async def main():
    """
    Index
    """
    content = """
    <body>
        <h1>Orion V.0</h1>
        <h2>Index</h2>
        <h5>©Matheus&Nivea</h5>
    </body>
    """
    return HTMLResponse(content=content)


@app.get("/movies",response_model=list[schemas.Movie],status_code=200,tags=["movies"],summary="Leitura de todos os filmes disponíveis")
def get_movies(db: Session = Depends(get_db)):
    """
    Função que busca todos os filmes
    """
    movies = crud.get_movies(db, skip=0, limit=100)
    return movies

@app.get("/movies/{movie_id}",response_model=schemas.Movie, status_code=200,tags=["movies"],summary="Leitura de filme especificado pela id")
def get_movie(movie_id: Annotated[int, Path(description="Id do filme desejado")],db: Session = Depends(get_db)):
     
    """
    Função que busca o filme de acordo com o id
    """
    db_movie = crud.get_movie(db, movie_id=movie_id)
    if db_movie is None:
        raise HTTPException(status_code=404, detail="Movie not found")
    return db_movie

@app.post("/movies",status_code=201,response_model=schemas.Movie,tags=["movies"],summary="Cadastro de um novo filme")
def create_movie(movie: schemas.MovieCreate,db: Session = Depends(get_db)):
    """
    Função que cadastra o filme

    """
    return crud.create_movie(db=db, movie=movie)

@app.put("/movies/{movie_id}",response_model=schemas.Movie,status_code=200,tags=["movies"],summary="Update de algum filme já disponível")
def update_movie(movie: schemas.MovieUpdate,movie_id: Annotated[int, Path(description="Id do filme desejado")],db: Session = Depends(get_db)):

    """
    Função que altera o filme ja existente
    """
    return crud.update_movie(db=db,movie=movie,movie_id=movie_id)

@app.delete("/movies/{movie_id}",status_code=200,tags=["movies"],summary="Exclusão de um filme no sistema")
def delete_movie(movie_id: Annotated[int, Path(description="Id do filme desejado")],db: Session = Depends(get_db)):

    """
    Função que deleta o filme e por cascata, as avaliações desse filme.
    """
    if crud.delete_movie(db=db,movie_id=movie_id):
        return {'response':'Sucessfully deleted!'}
    raise HTTPException(status_code=404, detail="Movie not found")


@app.get("/reviews",response_model=list[schemas.Review],status_code=200,tags=["reviews"],summary="Leitura de todas as reviews cadastradas")
def get_reviews(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):

    """
    Função que retorna todas as avaliacoes para todos os filmes
    """
    reviews = crud.get_reviews(db)
    return reviews

@app.get("/reviews/{movie_id}",response_model=list[schemas.Review],status_code=200,tags=["reviews"],summary="Leitura de todas as reviews para um filme especificado")
def get_reviews_by_movie(movie_id: Annotated[int, Path(description="Id do filme desejado")],db: Session = Depends(get_db)):

    """
    Função que retorna todas as avaliacoes que o filme tenha
    """
    db_reviews = crud.get_review_by_movie(db, movie_id=movie_id)
    if not len(db_reviews):
        raise HTTPException(status_code=404, detail="Movie has not reviews")
    return db_reviews


@app.post("/reviews/{movie_id}",response_model=schemas.Review,status_code=201,tags=["reviews"],summary="Cadastro de uma nova reviews sobre um filme")
def create_review(movie_id:Annotated[int, Path(description="Id do filme desejado")], review: schemas.ReviewCreate, db: Session = Depends(get_db)):
    
    """
    Função que cria uma avaliacao para um filme
    """
    return crud.create_review(db=db, review=review,movie_id=movie_id)

@app.put("/reviews/{review_id}",status_code=200,tags=["reviews"],summary="Update de uma review já cadastrada")
async def update_review(review: schemas.ReviewUpdate,review_id: Annotated[int, Path(description="Id do Review desejado")], db: Session = Depends(get_db)):

    """
    Função que atualiza uma avaliacao para um filme
    """

    return crud.update_review(db=db,review=review,review_id=review_id)

@app.delete("/reviews/{review_id}",status_code=200,tags=["reviews"],summary="Exclusão de uma review já cadastrada")
async def delete_movie(review_id: Annotated[int, Path(description="Id do Review desejado")],db: Session = Depends(get_db)):

    """
    Função que deleta um filme
    """

    if crud.delete_review(db=db,review_id=review_id):
        return {'response':'Sucessfully deleted!'}
    raise HTTPException(status_code=404, detail="Review not found")

@app.get("/average/{movie_id}",status_code=200,tags=["reviews",'movies'],summary="Leitura do rating médio de um filme cadastrado")
def get_average_rating(movie_id: Annotated[int, Path(description="Id do Review desejado")],db: Session = Depends(get_db)):

    """
    Função que faz a media de avaliacoes de filmes
    """
    average = crud.get_average(db=db,movie_id=movie_id)
    if average is not None:
        return crud.get_average(db=db,movie_id=movie_id)
    return {'response':'Reviews not found for the movie'}
