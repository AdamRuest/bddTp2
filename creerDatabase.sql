SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

CREATE SCHEMA IF NOT EXISTS `mydb` DEFAULT CHARACTER SET utf8 ;
USE `mydb` ;

DROP TABLE IF EXISTS table_joueurs;
CREATE TABLE IF NOT EXISTS `mydb`.`table_joueurs` (
  `id` INT NOT NULL,
  `nom` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`id`));

DROP TABLE IF EXISTS table_parties;
CREATE TABLE IF NOT EXISTS `mydb`.`table_parties` (
  `idPartie` INT NOT NULL,
  `tour` VARCHAR(1) DEFAULT 'O' NOT NULL,
  `idJoueurX` INT NOT NULL,
  `idJoueurO` INT NOT NULL,
  `gagant` INT NULL,
  `etatDeLaPartie` INT DEFAULT 0 NULL,
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

