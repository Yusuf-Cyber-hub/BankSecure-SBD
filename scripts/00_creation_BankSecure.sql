-- =====================================================================
-- Projet SBD : Securite des bases de donnees transactionnelles
-- Groupe 7 | Professeur : Ali KARTIT
-- Script 00 : creation de la base BankSecure + donnees de test
--
-- Responsable : Membre 1
-- Regles :
--   * Rejouable : peut etre execute autant de fois que necessaire
--     (supprime puis recree la base = remise a zero des demos).
--   * Aucun chemin de fichier : SQL Server utilise ses dossiers par defaut.
--   * Aucune donnee reelle : tous les noms, CIN et emails sont fictifs.
--   * Ne pas modifier la structure des tables sans prevenir Membre 1.
--
-- ATTENTION : l'execution ferme les connexions ouvertes sur BankSecure
-- (ROLLBACK IMMEDIATE). Fermer les autres fenetres de requete avant.
-- =====================================================================

USE master;
GO

-- 1) Suppression de l'ancienne base (si elle existe) --------------------
IF DB_ID(N'BankSecure') IS NOT NULL
BEGIN
    ALTER DATABASE BankSecure SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankSecure;
END
GO

-- 2) Creation de la base ------------------------------------------------
CREATE DATABASE BankSecure;
GO

-- Modele de recuperation FULL : necessaire pour la demo 8
-- (sauvegarde du journal de transactions + restauration a un instant precis).
ALTER DATABASE BankSecure SET RECOVERY FULL;
GO

USE BankSecure;
GO

-- 3) Tables -------------------------------------------------------------

-- Clients (id, nom, CIN, email)
CREATE TABLE dbo.Clients (
    id    INT IDENTITY(1,1) CONSTRAINT PK_Clients PRIMARY KEY,
    nom   NVARCHAR(100) NOT NULL,
    CIN   NVARCHAR(20)  NOT NULL CONSTRAINT UQ_Clients_CIN UNIQUE,
    email NVARCHAR(150) NOT NULL
);
GO

-- Comptes (id, client_id, solde, type)
-- Regle de coherence : un solde ne peut jamais etre negatif.
CREATE TABLE dbo.Comptes (
    id        INT IDENTITY(1,1) CONSTRAINT PK_Comptes PRIMARY KEY,
    client_id INT NOT NULL
              CONSTRAINT FK_Comptes_Clients REFERENCES dbo.Clients(id),
    solde     DECIMAL(18,2) NOT NULL
              CONSTRAINT DF_Comptes_solde DEFAULT 0
              CONSTRAINT CK_Comptes_solde CHECK (solde >= 0),
    type      NVARCHAR(20) NOT NULL
              CONSTRAINT CK_Comptes_type CHECK (type IN (N'Courant', N'Epargne'))
);
GO

-- Virements (id, compte_source, compte_dest, montant, date, statut)
-- Note : la colonne "date" du plan s'appelle date_virement (evite le mot-cle DATE).
CREATE TABLE dbo.Virements (
    id            INT IDENTITY(1,1) CONSTRAINT PK_Virements PRIMARY KEY,
    compte_source INT NOT NULL
                  CONSTRAINT FK_Virements_Source REFERENCES dbo.Comptes(id),
    compte_dest   INT NOT NULL
                  CONSTRAINT FK_Virements_Dest REFERENCES dbo.Comptes(id),
    montant       DECIMAL(18,2) NOT NULL
                  CONSTRAINT CK_Virements_montant CHECK (montant > 0),
    date_virement DATETIME2(0) NOT NULL
                  CONSTRAINT DF_Virements_date DEFAULT SYSDATETIME(),
    statut        NVARCHAR(20) NOT NULL
                  CONSTRAINT DF_Virements_statut DEFAULT N'En attente'
                  CONSTRAINT CK_Virements_statut
                      CHECK (statut IN (N'En attente', N'Valide', N'Echoue', N'Annule')),
    CONSTRAINT CK_Virements_comptes CHECK (compte_source <> compte_dest)
);
GO

-- AuditLog (id, utilisateur, action, date)
-- Note : la colonne "date" du plan s'appelle date_action.
CREATE TABLE dbo.AuditLog (
    id          INT IDENTITY(1,1) CONSTRAINT PK_AuditLog PRIMARY KEY,
    utilisateur SYSNAME NOT NULL
                CONSTRAINT DF_AuditLog_utilisateur DEFAULT SUSER_SNAME(),
    action      NVARCHAR(200) NOT NULL,
    date_action DATETIME2(0) NOT NULL
                CONSTRAINT DF_AuditLog_date DEFAULT SYSDATETIME()
);
GO

-- 4) Donnees de test (fictives) -----------------------------------------

INSERT INTO dbo.Clients (nom, CIN, email) VALUES
    (N'Yassine El Amrani', N'AB123456', N'yassine.elamrani@example.com'),
    (N'Salma Benali',      N'BK234567', N'salma.benali@example.com'),
    (N'Omar Tazi',         N'CD345678', N'omar.tazi@example.com'),
    (N'Khadija Idrissi',   N'EE456789', N'khadija.idrissi@example.com'),
    (N'Mehdi Alaoui',      N'FH567890', N'mehdi.alaoui@example.com');
GO

-- Les ids sont attribues dans l'ordre (1 a 8) car la base est recreee a neuf.
-- Compte 1 (1000 DH) sert aux demos de concurrence (lost update).
-- Comptes 1 et 2 servent aux demos de deadlock.
INSERT INTO dbo.Comptes (client_id, solde, type) VALUES
    (1,  1000.00, N'Courant'),   -- compte 1
    (1,  5000.00, N'Epargne'),   -- compte 2
    (2,  2500.00, N'Courant'),   -- compte 3
    (3, 12000.00, N'Courant'),   -- compte 4
    (3, 30000.00, N'Epargne'),   -- compte 5
    (4,   800.00, N'Courant'),   -- compte 6
    (5, 15000.00, N'Courant'),   -- compte 7
    (5,   100.00, N'Epargne');   -- compte 8
GO

INSERT INTO dbo.Virements (compte_source, compte_dest, montant, statut) VALUES
    (1, 3,  200.00, N'Valide'),
    (4, 6,  500.00, N'Valide'),
    (7, 2, 1500.00, N'Valide'),
    (3, 1,  100.00, N'Echoue');
GO

INSERT INTO dbo.AuditLog (action) VALUES
    (N'Creation de la base BankSecure et chargement des donnees de test');
GO

-- 5) Verification -------------------------------------------------------

PRINT N'BankSecure cree avec succes.';

SELECT N'Clients'   AS [table], COUNT(*) AS lignes FROM dbo.Clients
UNION ALL
SELECT N'Comptes',   COUNT(*) FROM dbo.Comptes
UNION ALL
SELECT N'Virements', COUNT(*) FROM dbo.Virements
UNION ALL
SELECT N'AuditLog',  COUNT(*) FROM dbo.AuditLog;

SELECT id, client_id, solde, type FROM dbo.Comptes;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO
