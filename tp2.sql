CREATE DATABASE IF NOT EXISTS TicTacToe;
USE TicTacToe;

CREATE TABLE IF NOT EXISTS table_boards
(
	id INT,
    x INT NOT NULL,
    y INT NOT NULL,
    value VARCHAR(1) NULL,
    CONSTRAINT position PRIMARY KEY (ID, X, Y)
);

CREATE TABLE IF NOT EXISTS table_games
(
	boardId INT,
    turn VARCHAR(1),
    gameState INT,
    -- 0 = Not exist
    -- 1 = Ongoing
    -- 2 = Over
    playerO VARCHAR(45),
    playerX VARCHAR(45),
    winner VARCHAR(1)
);

DELIMITER |

DROP PROCEDURE IF EXISTS createNewGame|
CREATE PROCEDURE createNewGame(gameId INT, playerO VARCHAR(45), playerX VARCHAR(45))
BEGIN
	SET @isGameExist = (SELECT boardId from table_games WHERE table_games.boardID = gameId);
    
    IF @isGameExist != NULL
		THEN INSERT INTO table_games VALUES (gameId, 'O', 1, playerO, playerX);
    END IF;
END|

DROP PROCEDURE IF EXISTS  playGame|
CREATE PROCEDURE playerMove(boardId INT, columnMove INT, rowMove INT, value VARCHAR(1))
BEGIN
	-- Check if the game is ongoing
	IF (SELECT gameState FROM table_games WHERE table_games.boardId = boardId) = 2
		THEN (SELECT 'This game is already over');
	END IF;
    -- Check if the game exists
    IF (SELECT gameState FROM table_games WHERE table_games.boardId = boardId) = NULL
		THEN (SELECT 'This game does not exist');
	END IF;
    -- Check if the move is illegal
    IF (SELECT value FROM table_boards WHERE id = boardId AND x = columnMove AND y = rowMove) != NULL
        THEN
			SET @PLAYER = (SELECT turn FROM table_games WHERE table_games.boardId = boardId);
			SELECT (CONCAT('This move is illegal. The winner is ', CASE WHEN @PLAYER = 'X' THEN 'O' WHEN @PLAYER = 'O' THEN 'X' END));
			CALL cheatHandle(boardId);
	END IF;
    -- Check if player entry is valid
	IF value NOT IN ('X', 'O')
		THEN (SELECT CONCAT(value, ' is not a valid player, player must be X or O!'));
	END IF;
    -- Check if rowMove is valid
    IF rowMove > 2
		THEN (SELECT 'Move out of range. Max: 2');
	END IF;
    -- Check if columnMove is valid
    IF columnMove > 2
		THEN (SELECT 'Move out of range. Max: 2');
	END IF;
    -- Check if it is the correct player
    IF (SELECT turn FROM table_games WHERE table_games.boardId = boardId) = value
		THEN 	
			INSERT INTO table_boards VALUES (boardId, columnMove, rowMove, value);
			UPDATE table_games SET turn = CASE WHEN turn = 'X' THEN 'O' WHEN turn = 'O' THEN 'X' END WHERE tables_games.boardId = boardId;
			CALL checkForVictory(boardId);
    ELSE
		SET @PLAYER = 	CASE
							WHEN (SELECT turn FROM table_games WHERE table_games.boardId = boardId) = 'X' THEN CONCAT((SELECT playerX FROM table_games WHERE table_games.boardId = boardId))
                            WHEN (SELECT turn FROM table_games WHERE table_games.boardId = boardId) = 'O' THEN CONCAT((SELECT playerO FROM table_games WHERE table_games.boardId = boardId))
						END;
		SELECT (CONCAT('This isn\'t your turn. The winner is ', @PLAYER, ' (', (SELECT turn FROM table_games WHERE table_games.boardId = boardId), ')'));
		CALL cheatHandle(boardId);
	END IF;
END|

DROP PROCEDURE IF EXISTS checkForVictory|
CREATE PROCEDURE checkForVictory(boardId INT)
BEGIN
	SET
		@tile00 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 0),
        @tile01 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 1),
        @tile02 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 2),
        @tile10 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 0),
        @tile11 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 1),
        @tile12 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 2),
        @tile20 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 0),
        @tile21 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 1),
        @tile22 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 2);
	
    IF @tile00 = @tile01 AND @tile01 = @tile02
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile00 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile00 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile00 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile10 = @tile11 AND @tile11 = @tile12
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile10 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile10 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile10 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile20 = @tile21 AND @tile21 = @tile22
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile20 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile20 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile20 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile00 = @tile10 AND @tile10 = @tile20
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile00 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile00 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile00 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile01 = @tile11 AND @tile11 = @tile21
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile01 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile01 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile01 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile02 = @tile21 AND @tile21 = @tile22
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile02 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile02 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile02 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile00 = @tile11 AND @tile11 = @tile22
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile00 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile00 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile00 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
    IF @tile02 = @tile11 AND @tile11 = @tile20
     THEN 
		SELECT(CONCAT(CASE
						WHEN @tile02 = 'X' THEN (SELECT playerX FROM table_games WHERE table_games.boardId = boardId)
                        WHEN @tile02 = 'O' THEN (SELECT playerO FROM table_games WHERE table_games.boardId = boardId)
					  END, ' is the winner!'));
        UPDATE table_games SET winner = @tile02 WHERE table_games.boardId = boardId;
        UPDATE table_games SET gameState = 2 WHERE table_games.boardId = boardId;
	END IF;
END|

DROP PROCEDURE IF EXISTS displayGame|
CREATE PROCEDURE displayGame(boardId INT)
BEGIN
	SET
		@tile00 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 0),
        @tile01 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 1),
        @tile02 = (SELECT value FROM table_boards WHERE id = boardId AND x = 0 AND y = 2),
        @tile10 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 0),
        @tile11 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 1),
        @tile12 = (SELECT value FROM table_boards WHERE id = boardId AND x = 1 AND y = 2),
        @tile20 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 0),
        @tile21 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 1),
        @tile22 = (SELECT value FROM table_boards WHERE id = boardId AND x = 2 AND y = 2),
        @gameStatus = (SELECT gameState FROM table_games WHERE table_games.boardId = boardId),
        @playerO = (SELECT playerO FROM table_games WHERE table_games.boardId = boardId),
        @playerX = (SELECT playerO FROM table_games WHERE table_games.boardId = boardId);
        
	IF @tile00 = NULL
		THEN SET @tile00 = '-';
	END IF;
    IF @tile01 = NULL
		THEN SET @tile01 = '-';
	END IF;
    IF @tile02 = NULL
		THEN SET @tile02 = '-';
	END IF;
    IF @tile10 = NULL
		THEN SET @tile00 = '-';
	END IF;
    IF @tile11 = NULL
		THEN SET @tile11 = '-';
	END IF;
    IF @tile12 = NULL
		THEN SET @tile12 = '-';
	END IF;
    IF @tile20 = NULL
		THEN SET @tile20 = '-';
	END IF;
    IF @tile21 = NULL
		THEN SET @tile21 = '-';
	END IF;
    IF @tile22 = NULL
		THEN SET @tile22 = '-';
	END IF;
    SELECT CONCAT(
    CASE
		WHEN @gameStatus = null THEN 'This game does not exist'
        WHEN @gameStatus = 1 THEN CONCAT('Game number: ', boardId, char(10),
										'It is ', 
										CASE
											WHEN (SELECT turn FROM table_games WHERE table_games.boardId = boardId) = 'X' THEN (SELECT playerX from table_games WHERE table_games.boardId = boardId)
                                            WHEN (SELECT turn FROM table_games WHERE table_games.boardId = boardId) = 'O' THEN (SELECT playerO from table_games WHERE table_games.boardId = boardId)
										END, ' (', (SELECT turn FROM table_games WHERE table_games.boardId = boardId), ')', ' turn\'s to play')
        WHEN @gameStatus = 2 THEN CONCAT('Game number: ', boardId, char(10),
										'This game is over, the winner is ', 
										CASE
											WHEN (SELECT winner FROM table_games WHERE table_games.boardId = boardId) = 'X' THEN (SELECT playerX from table_games WHERE table_games.boardId = boardId)
                                            WHEN (SELECT winner FROM table_games WHERE table_games.boardId = boardId) = 'O' THEN (SELECT playerO from table_games WHERE table_games.boardId = boardId)
										END)
	END,
    @tile00, @tile01, @tile02, Char(10), 
    @tile10, @tile11, @tile12, Char(10), 
    @tile02, @tile12, @tile22, Char(10),
    @playerO, ' vs ', @playerX);
END|

DROP PROCEDURE IF EXISTS cheatHandle|
CREATE PROCEDURE cheatHandle(boardId INT)
BEGIN
	SET @PLAYER = (SELECT turn FROM table_games WHERE table_games.boardId = boardId);
    CASE 
		WHEN @PLAYER = 'X'
        THEN 
			UPDATE table_games SET winner = 'O' AND gameState = 2 WHERE table_games.boardId = boardId;
		WHEN @PLAYER = 'O'
        THEN 
			UPDATE table_games SET winner = 'X' AND gameState = 2 WHERE table_games.boardId = boardId;
	END CASE;
END|

DELIMITER ;