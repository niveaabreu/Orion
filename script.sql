DROP DATABASE IF EXISTS movies;
CREATE DATABASE movies;
USE movies;

CREATE TABLE movies (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL UNIQUE,
    director VARCHAR(100) NOT NULL,
    release_year INT NOT NULL
);

CREATE TABLE reviews (
    id INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT,
    review_comment VARCHAR(100) NOT NULL,
    rating FLOAT NOT NULL,
    movie_id INTEGER NOT NULL,
    FOREIGN KEY (movie_id) REFERENCES movies (id)
);

INSERT INTO movies (id, title,director,release_year)
  VALUES ( 1, 'Reply 1998','Kwang KO',2014 ),
  ( 2, 'De repente 30','Martin Scocese',2004 ),
  ( 3, 'Mario','John Travolta',2023 );
  
INSERT INTO reviews (id, review_comment,rating,movie_id)
  VALUES ( 1, 'Muito bom, me emocionei!', 9.5 , 1 ),
          ( 2, 'Muito bom o filme',9,1 ),
          ( 3, 'Muito brega',7,2 ),
          ( 4, 'Um clássico',10,2 ),
          ( 5, 'Gostei!',9,3 );