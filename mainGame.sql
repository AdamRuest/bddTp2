SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

CREATE TABLE IF NOT EXISTS `mydb`.`table_joueurs` (
  `id` INT NOT NULL,
  `nom` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`));

CREATE TABLE IF NOT EXISTS `mydb`.`table_parties` (
  `idPartie` INT NOT NULL,
  `tour` VARCHAR(1) NOT NULL,
  `idJoueurX` INT NOT NULL,
  `idJoueurO` INT NOT NULL,
  `gagant` INT NULL,
  `etatDeLaPartie` INT NULL,
  PRIMARY KEY (`idPartie`),
  INDEX `fk_table_parties_table_joueurs_idx` (`idJoueurX` ASC),
  INDEX `fk_table_parties_table_joueurs1_idx` (`idJoueurO` ASC),
  CONSTRAINT `fk_table_parties_table_joueurs`
    FOREIGN KEY (`idJoueurX`)
    REFERENCES `mydb`.`table_joueurs` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_table_parties_table_joueurs1`
    FOREIGN KEY (`idJoueurO`)
    REFERENCES `mydb`.`table_joueurs` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
    
CREATE TABLE IF NOT EXISTS `mydb`.`table_tableaux` (
  `id` INT NOT NULL,
  `idPartie` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_table_tableaux_table_parties1_idx` (`idPartie` ASC),
  CONSTRAINT `fk_table_tableaux_table_parties1`
    FOREIGN KEY (`idPartie`)
    REFERENCES `mydb`.`table_parties` (`idPartie`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

CREATE TABLE IF NOT EXISTS `mydb`.`table_cellules` (
  `id` INT NOT NULL,
  `x` INT NOT NULL,
  `y` INT NOT NULL,
  `valeur` VARCHAR(1) NOT NULL,
  `idTableau` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_table_cellules_table_tableaux1_idx` (`idTableau` ASC),
  CONSTRAINT `fk_table_cellules_table_tableaux1`
    FOREIGN KEY (`idTableau`)
    REFERENCES `mydb`.`table_tableaux` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

DELIMITER |

DROP TRIGGER IF EXISTS startGame|
CREATE TRIGGER startGame 
AFTER INSERT ON mydb.table_parties
FOR EACH ROW
BEGIN
	DECLARE gameId INT;
    
    SELECT idPartie INTO gameId FROM mydb.table_partie WHERE idPartie = LAST_INSERT_ID();
    
    UPDATE mydb.table_parties SET tour = 'O' AND etatDeLaPartie = 1 WHERE idPartie = gameId;
    INSERT INTO mydb.table_tableaux VALUE (gameId, gameId);
    INSERT INTO mydb.table_cellules VALUE
    ((1, 0, 0, '-', @gameId),
    (2, 0, 1, '-', @gameId),
    (3, 0, 2, '-', @gameId),
    (4, 1, 0, '-', @gameId),
    (5, 1, 1, '-', @gameId),
    (6, 1, 2, '-', @gameId),
    (7, 2, 0, '-', @gameId),
    (8, 2, 1, '-', @gameId),
    (9, 2, 2, '-', @gameId));
END|

DROP TRIGGER IF EXISTS checkMove|
CREATE TRIGGER checkMove 
AFTER UPDATE ON mydb.table_cellules
FOR EACH ROW
BEGIN
	DECLARE playerTurn VARCHAR(1);
	DECLARE gameId INT;
	DECLARE moveId INT;
	DECLARE positionX INT;
	DECLARE positionY INT;
    DECLARE moveValue VARCHAR(1);
    DECLARE cellValue VARCHAR(1);
	
    SELECT idTableau, id, valeur INTO gameId, moveId, moveValue FROM NEW;
    SELECT x, y, valeur INTO positionX, positionY, cellValue FROM mydb.table_cellules WHERE id = moveId AND idTableau = gameId;
    SELECT tour INTO playerTurn FROM table_parties WHERE idPartie = gameId;
    
	-- Check if game is over
	IF (SELECT etatDeLaPartie FROM mydb.table_parties WHERE idPartie = gameId) = 2 THEN 
		
		CALL displayPrompt('This game is already over!');
	END IF;
    -- Check if game exist
    IF (SELECT etatDeLaPartie FROM mydb.table_parties WHERE idPartie = gameId) = NULL THEN 
		-- ROLLBACK;
        CALL displayPrompt('This game does not exist!');
	END IF;
    -- Check if move is legal
    IF cellValue != '-' THEN 
        -- ROLLBACK;
		CALL cheatHandle(gameId, 0);
        CALL displayPrompt('This tile is not empty!');
	END IF;
    IF positionX > 2 OR positionY > 2 THEN 
        -- ROLLBACK;
        CALL cheatHandle(gameId, 0);
		CALL displayPrompt('Move out of range!');
	END IF;
    -- Check if it is the correct player
    IF moveValue != tour THEN
        -- ROLLBACK;
        CALL cheatHandle(gameId, 1);
        CALL displayPrompt('This isn\'t your turn!');
	-- The Move is legal
	ELSE
		UPDATE table_parties SET tour = CASE WHEN playerTurn = 'X' THEN 'O' WHEN playerTurn = 'O' THEN 'X' END WHERE idPartie = gameId;
        CALL checkForVictory(gameId);
	END IF;
END|

DROP PROCEDURE IF EXISTS displayPrompt|
CREATE PROCEDURE displayPrompt(prompt TEXT, OUT output TEXT)
BEGIN
	SET output = prompt;
END|

DROP PROCEDURE IF EXISTS checkForVictory|
CREATE PROCEDURE checkForVictory(gameId INT, OUT winnerPrompt VARCHAR(1000))
BEGIN
	DECLARE cell00 VARCHAR(1);
    DECLARE cell01 VARCHAR(1);
    DECLARE cell02 VARCHAR(1);
    DECLARE cell10 VARCHAR(1);
    DECLARE cell11 VARCHAR(1);
    DECLARE cell12 VARCHAR(1);
    DECLARE cell20 VARCHAR(1);
    DECLARE cell21 VARCHAR(1);
    DECLARE cell22 VARCHAR(1);
    DECLARE winner INT;
    DECLARE winnerName VARCHAR(45);
    DECLARE winnerSymbol VARCHAR(1);
    DECLARE returnValue VARCHAR(1000);
    
    SELECT valeur INTO cell00 FROM table_cellules WHERE x = 0 AND y = 0 AND idPartie = gameId;
    SELECT valeur INTO cell01 FROM table_cellules WHERE x = 0 AND y = 1 AND idPartie = gameId;
    SELECT valeur INTO cell02 FROM table_cellules WHERE x = 0 AND y = 2 AND idPartie = gameId;
    SELECT valeur INTO cell10 FROM table_cellules WHERE x = 1 AND y = 0 AND idPartie = gameId;
    SELECT valeur INTO cell11 FROM table_cellules WHERE x = 1 AND y = 1 AND idPartie = gameId;
    SELECT valeur INTO cell12 FROM table_cellules WHERE x = 1 AND y = 2 AND idPartie = gameId;
    SELECT valeur INTO cell20 FROM table_cellules WHERE x = 2 AND y = 0 AND idPartie = gameId;
    SELECT valeur INTO cell21 FROM table_cellules WHERE x = 2 AND y = 1 AND idPartie = gameId;
    SELECT valeur INTO cell22 FROM table_cellules WHERE x = 2 AND y = 2 AND idPartie = gameId;
    
    IF cell00 = cell01 AND cell01 = cell02 THEN
		CASE 
			WHEN cell00 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell00 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;	
	IF cell10 = cell11 AND cell11 = cell12 THEN
		CASE 
			WHEN cell10 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell10 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell20 = cell21 AND cell21 = cell22 THEN
		CASE 
			WHEN cell20 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell20 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell00 = cell10 AND cell10 = cell20 THEN
		CASE 
			WHEN cell00 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell00 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell01 = cell11 AND cell11 = cell21 THEN
		CASE 
			WHEN cell01 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell01 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell02 = cell12 AND cell12 = cell22 THEN
		CASE 
			WHEN cell00 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell00 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell00 = cell11 AND cell11 = cell22 THEN
		CASE 
			WHEN cell00 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell00 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    IF cell20 = cell11 AND cell11 = cell02 THEN
		CASE 
			WHEN cell20 = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'X';
			WHEN cell20 = 'O'	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
                                    SET winnerSymbol = 'O';
		END CASE;
        SET returnValue := CONCAT('Game over! The winner is ', winnerName, '(', winnerSymbol, ')');
        UPDATE table_partie SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
	END IF;
    
    SET winnerPrompt = returnValue;
END|

DROP PROCEDURE IF EXISTS cheatHandle|
CREATE PROCEDURE cheatHandle(gameId INT, outOfTurn INT, OUT winnerPrompt VARCHAR(1000))
BEGIN
	DECLARE joueur VARCHAR(1);
	DECLARE winner INT;
    DECLARE winnerName VARCHAR(45);
    
    SELECT tour INTO joueur FROM mydb.table_parties WHERE idPartie = gameId;
    
    IF outOfTurn = 0 THEN
		CASE
			WHEN joueur = 'X' 	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
			WHEN joueur = 'O' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
		END CASE;
	ELSE 
		CASE
			WHEN joueur = 'X' 	THEN 
									SELECT idJoueurX INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
			WHEN joueur = 'O' 	THEN 
									SELECT idJoueurO INTO winner FROM table_parties WHERE idPartie = gameId;
									SELECT nom INTO winnerName FROM table_joueurs WHERE id = winner;
		END CASE;
	END IF;
    
    UPDATE table_parties SET gagnant = winner AND etatDeLaPartie = 2 WHERE idPartie = gameId;
    SET winnerPrompt := CONCAT('The winner is ', winnerName, '(', CASE WHEN joueur = 'X' THEN 'O' WHEN joueur = 'O' THEN 'X' END, ')');
END|

DROP PROCEDURE IF EXISTS displayGame|
CREATE PROCEDURE displayGame(gameId INT, OUT returnValue VARCHAR(1000))
BEGIN
	DECLARE tile00 VARCHAR(1);
    DECLARE tile01 VARCHAR(1);
    DECLARE tile02 VARCHAR(1);
    DECLARE tile10 VARCHAR(1);
    DECLARE tile11 VARCHAR(1);
    DECLARE tile12 VARCHAR(1);
    DECLARE tile20 VARCHAR(1);
    DECLARE tile21 VARCHAR(1);
    DECLARE tile22 VARCHAR(1);
    DECLARE gameState INT;
    DECLARE playerO VARCHAR(45);
    DECLARE playerX VARCHAR(45);
    DECLARE turn VARCHAR(1);
    DECLARE winner VARCHAR(45);
    
    SELECT valeur INTO tile00 FROM table_cellules WHERE idPartie = gameId AND x = 0 AND y = 0;
    SELECT valeur INTO tile01 FROM table_cellules WHERE idPartie = gameId AND x = 0 AND y = 1;
    SELECT valeur INTO tile02 FROM table_cellules WHERE idPartie = gameId AND x = 0 AND y = 2;
    SELECT valeur INTO tile10 FROM table_cellules WHERE idPartie = gameId AND x = 1 AND y = 0;
    SELECT valeur INTO tile11 FROM table_cellules WHERE idPartie = gameId AND x = 1 AND y = 1;
    SELECT valeur INTO tile12 FROM table_cellules WHERE idPartie = gameId AND x = 1 AND y = 2;
    SELECT valeur INTO tile20 FROM table_cellules WHERE idPartie = gameId AND x = 2 AND y = 0;
    SELECT valeur INTO tile21 FROM table_cellules WHERE idPartie = gameId AND x = 2 AND y = 1;
    SELECT valeur INTO tile22 FROM table_cellules WHERE idPartie = gameId AND x = 2 AND y = 2;
	SELECT etatDeLaPartie INTO gameState FROM table_parties WHERE idPartie = gameId;
    SELECT nom INTO winner FROM table_joueurs WHERE id = (SELECT gagnant FROM table_parties WHERE idPartie = gameId);
    SELECT nom INTO playerO FROM table_joueurs WHERE id = (SELECT idPlayerO FROM table_parties WHERE idPartie = gameId);
    SELECT nom INTO playerX FROM table_joueurs WHERE id = (SELECT idPlayerX FROM table_parties WHERE idPartie = gameId);
    SELECT tour INTO turn FROM table_parties WHERE idPartie = gameId;
        
    SET returnValue := CONCAT(
    CASE
		WHEN gameState = null THEN 'This game does not exist'
        WHEN gameState = 1 THEN CONCAT('Game number: ', gameId, char(10),
										'It is ', 
										CASE
											WHEN turn = 'X' THEN playerX
                                            WHEN turn = 'O' THEN playerO
										END, ' (', turn, ')', ' turn\'s to play')
        WHEN gameStatus = 2 THEN 
								CONCAT('Game number: ', gameId, char(10),
										'This game is over, the winner is ', winner)
	END,
    tile00, tile01, tile02, Char(10), 
    tile10, tile11, tile12, Char(10), 
    tile02, tile12, tile22, Char(10),
    playerO, ' vs ', playerX);
END|