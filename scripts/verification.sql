-- =====================================================================
-- Projet SBD : Securite des bases de donnees transactionnelles
-- Groupe 7 | Professeur : Ali KARTIT
-- Script 00b : verification de la creation de BankSecure (Task 01)
--
-- A lancer APRES 00_creation_BankSecure.sql.
-- Ne modifie aucune donnee (les tests de contraintes sont annules).
-- Conseil captures : selectionner UNE section, puis Execute (F5).
-- =====================================================================

USE BankSecure;
GO

-- ---------------------------------------------------------------------
-- POINT 2 : les 4 tables existent
-- Attendu : 4 lignes (AuditLog, Clients, Comptes, Virements)
-- ---------------------------------------------------------------------
SELECT name AS nom_table
FROM sys.tables
ORDER BY name;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- POINT 3 : cles primaires (PK)
-- Attendu : 4 lignes, une PK par table
-- ---------------------------------------------------------------------
SELECT t.name AS [table],
       kc.name AS contrainte_PK,
       c.name AS colonne
FROM sys.key_constraints AS kc
JOIN sys.tables AS t
     ON kc.parent_object_id = t.object_id
JOIN sys.index_columns AS ic
     ON ic.object_id = kc.parent_object_id
    AND ic.index_id  = kc.unique_index_id
JOIN sys.columns AS c
     ON c.object_id = ic.object_id
    AND c.column_id = ic.column_id
WHERE kc.type = 'PK'
ORDER BY t.name;

-- Cles etrangeres (FK)
-- Attendu : 3 lignes
--   Comptes.client_id        -> Clients
--   Virements.compte_source  -> Comptes
--   Virements.compte_dest    -> Comptes
SELECT fk.name AS contrainte_FK,
       OBJECT_NAME(fk.parent_object_id) AS table_enfant,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS colonne,
       OBJECT_NAME(fk.referenced_object_id) AS table_parent
FROM sys.foreign_keys AS fk
JOIN sys.foreign_key_columns AS fkc
     ON fk.object_id = fkc.constraint_object_id
ORDER BY table_enfant, fk.name;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- POINT 4 : contraintes CHECK et UNIQUE
-- Attendu CHECK : 5 lignes
--   CK_Comptes_solde, CK_Comptes_type, CK_Virements_montant,
--   CK_Virements_statut, CK_Virements_comptes
-- ---------------------------------------------------------------------
SELECT OBJECT_NAME(parent_object_id) AS [table],
       name AS contrainte_CHECK,
       definition
FROM sys.check_constraints
ORDER BY [table], name;

-- Attendu UNIQUE : 1 ligne (UQ_Clients_CIN)
SELECT OBJECT_NAME(parent_object_id) AS [table],
       name AS contrainte_UNIQUE
FROM sys.key_constraints
WHERE type = 'UQ';

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- Preuve par l'erreur : les contraintes refusent les mauvaises donnees.
-- Tout est annule a la fin (ROLLBACK), aucune donnee n'est modifiee.
BEGIN TRAN;

-- Test 1 : solde negatif. Attendu : erreur 547 (CHECK)
BEGIN TRY
    UPDATE dbo.Comptes SET solde = -50 WHERE id = 1;
END TRY
BEGIN CATCH
    SELECT N'Test solde negatif' AS test,
           ERROR_NUMBER() AS numero_erreur,
           ERROR_MESSAGE() AS message;
END CATCH;

-- Test 2 : CIN en double. Attendu : erreur 2627 (UNIQUE)
BEGIN TRY
    INSERT INTO dbo.Clients (nom, CIN, email)
    VALUES (N'Test Doublon', N'AB123456', N'doublon@example.com');
END TRY
BEGIN CATCH
    SELECT N'Test CIN en double' AS test,
           ERROR_NUMBER() AS numero_erreur,
           ERROR_MESSAGE() AS message;
END CATCH;

-- Test 3 : virement vers le meme compte. Attendu : erreur 547 (CHECK)
BEGIN TRY
    INSERT INTO dbo.Virements (compte_source, compte_dest, montant)
    VALUES (1, 1, 10.00);
END TRY
BEGIN CATCH
    SELECT N'Test virement meme compte' AS test,
           ERROR_NUMBER() AS numero_erreur,
           ERROR_MESSAGE() AS message;
END CATCH;

-- Test 4 : compte pour un client inexistant. Attendu : erreur 547 (FK)
BEGIN TRY
    INSERT INTO dbo.Comptes (client_id, solde, type)
    VALUES (999, 100.00, N'Courant');
END TRY
BEGIN CATCH
    SELECT N'Test client inexistant (FK)' AS test,
           ERROR_NUMBER() AS numero_erreur,
           ERROR_MESSAGE() AS message;
END CATCH;

IF @@TRANCOUNT > 0 ROLLBACK TRAN;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- POINT 5 : index ajoutes
-- Attendu : 3 lignes
--   IX_Comptes_client_id, IX_Virements_compte_source,
--   IX_Virements_compte_dest
-- ---------------------------------------------------------------------
SELECT OBJECT_NAME(object_id) AS [table],
       name AS nom_index,
       type_desc
FROM sys.indexes
WHERE name LIKE N'IX[_]%'
ORDER BY [table], name;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- POINT 6 : donnees de test et coherence des soldes
-- Attendu : 5 clients, 8 comptes, 4 virements, 1 ligne AuditLog
-- ---------------------------------------------------------------------
SELECT N'Clients' AS [table], COUNT(*) AS lignes FROM dbo.Clients
UNION ALL
SELECT N'Comptes',   COUNT(*) FROM dbo.Comptes
UNION ALL
SELECT N'Virements', COUNT(*) FROM dbo.Virements
UNION ALL
SELECT N'AuditLog',  COUNT(*) FROM dbo.AuditLog;

-- Total de la banque. Attendu : 66400.00
SELECT SUM(solde) AS total_banque FROM dbo.Comptes;

-- Aucun solde negatif. Attendu : 0
SELECT COUNT(*) AS comptes_negatifs
FROM dbo.Comptes
WHERE solde < 0;

-- Recalcul de chaque solde depuis les soldes initiaux et les virements
-- valides (les virements echoues ne comptent pas).
-- Attendu : controle = OK pour les 8 comptes
WITH initial AS (
    SELECT *
    FROM (VALUES
        (1,  1000.00),
        (2,  5000.00),
        (3,  2500.00),
        (4, 12000.00),
        (5, 30000.00),
        (6,   800.00),
        (7, 15000.00),
        (8,   100.00)
    ) AS v(id, solde_initial)
),
mouvement AS (
    SELECT c.id,
           ISNULL((SELECT SUM(montant) FROM dbo.Virements
                   WHERE compte_dest = c.id AND statut = N'Valide'), 0)
         - ISNULL((SELECT SUM(montant) FROM dbo.Virements
                   WHERE compte_source = c.id AND statut = N'Valide'), 0)
           AS net
    FROM dbo.Comptes AS c
)
SELECT c.id AS compte,
       i.solde_initial,
       m.net AS mouvement_net,
       i.solde_initial + m.net AS solde_attendu,
       c.solde AS solde_reel,
       CASE WHEN i.solde_initial + m.net = c.solde
            THEN N'OK' ELSE N'ERREUR' END AS controle
FROM dbo.Comptes AS c
JOIN initial   AS i ON i.id = c.id
JOIN mouvement AS m ON m.id = c.id
ORDER BY c.id;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- POINT 7 : RECOVERY FULL
-- Attendu : recovery_model_desc = FULL
-- ---------------------------------------------------------------------
SELECT name AS base,
       recovery_model_desc
FROM sys.databases
WHERE name = N'BankSecure';

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO

-- ---------------------------------------------------------------------
-- NOTION : DECIMAL vs FLOAT
-- FLOAT stocke des valeurs approchees, DECIMAL des valeurs exactes.
-- Attendu : float_test = different, decimal_test = egal
-- ---------------------------------------------------------------------
SELECT CASE WHEN CAST(0.1 AS FLOAT) + CAST(0.2 AS FLOAT) = CAST(0.3 AS FLOAT)
            THEN N'egal' ELSE N'different' END AS float_test,
       CASE WHEN CAST(0.1 AS DECIMAL(18,2)) + CAST(0.2 AS DECIMAL(18,2))
                 = CAST(0.3 AS DECIMAL(18,2))
            THEN N'egal' ELSE N'different' END AS decimal_test;

-- Types des colonnes monetaires de BankSecure. Attendu : decimal (18,2)
SELECT TABLE_NAME AS [table],
       COLUMN_NAME AS colonne,
       DATA_TYPE AS type_donnee,
       NUMERIC_PRECISION AS precision_,
       NUMERIC_SCALE AS echelle
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE = 'decimal';

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO