-- =====================================================================
-- Projet SBD : Securite des bases de donnees transactionnelles
-- Groupe 7 | Professeur : Ali KARTIT
-- Script 00 : creation de la base BankSecure + donnees de test
--
-- Responsable : Membre 1
--
-- Regles :
--   * Rejouable : supprime puis recree la base.
--   * Aucun chemin de fichier.
--   * Aucune donnee reelle.
--   * Compatible avec SQL Server 2025.
--
-- ATTENTION : l'execution ferme les connexions ouvertes sur BankSecure.
-- =====================================================================

USE master;
GO

-- 1) Suppression de l'ancienne base ------------------------------------

IF DB_ID(N'BankSecure') IS NOT NULL
BEGIN
    ALTER DATABASE BankSecure SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankSecure;
END
GO

-- 2) Creation de la base -----------------------------------------------

CREATE DATABASE BankSecure;
GO

-- Modele FULL : necessaire pour la demo 8 (backup du journal
-- de transactions et restauration a un instant precis).
ALTER DATABASE BankSecure SET RECOVERY FULL;
GO

USE BankSecure;
GO

-- 3) Creation des tables ------------------------------------------------

-- TABLE 1 : Clients
CREATE TABLE dbo.Clients (
    id    INT IDENTITY(1,1)
          CONSTRAINT PK_Clients PRIMARY KEY,
    nom   NVARCHAR(100) NOT NULL,
    CIN   NVARCHAR(20) NOT NULL
          CONSTRAINT UQ_Clients_CIN UNIQUE,
    email NVARCHAR(150) NOT NULL
);
GO

-- TABLE 2 : Comptes
-- Regle : le solde ne peut jamais etre negatif.
CREATE TABLE dbo.Comptes (
    id        INT IDENTITY(1,1)
              CONSTRAINT PK_Comptes PRIMARY KEY,

    client_id INT NOT NULL
              CONSTRAINT FK_Comptes_Clients
              REFERENCES dbo.Clients(id),

    solde     DECIMAL(18,2) NOT NULL
              CONSTRAINT DF_Comptes_solde DEFAULT 0
              CONSTRAINT CK_Comptes_solde CHECK (solde >= 0),

    type      NVARCHAR(20) NOT NULL
              CONSTRAINT CK_Comptes_type
              CHECK (type IN (N'Courant', N'Epargne'))
);
GO

-- TABLE 3 : Virements
-- Note : la colonne "date" du plan s'appelle date_virement
-- (DATE est un mot-cle SQL).
CREATE TABLE dbo.Virements (
    id            INT IDENTITY(1,1)
                  CONSTRAINT PK_Virements PRIMARY KEY,

    compte_source INT NOT NULL
                  CONSTRAINT FK_Virements_Source
                  REFERENCES dbo.Comptes(id),

    compte_dest   INT NOT NULL
                  CONSTRAINT FK_Virements_Dest
                  REFERENCES dbo.Comptes(id),

    montant       DECIMAL(18,2) NOT NULL
                  CONSTRAINT CK_Virements_montant CHECK (montant > 0),

    date_virement DATETIME2(0) NOT NULL
                  CONSTRAINT DF_Virements_date DEFAULT SYSDATETIME(),

    statut        NVARCHAR(20) NOT NULL
                  CONSTRAINT DF_Virements_statut DEFAULT N'En attente'
                  CONSTRAINT CK_Virements_statut
                  CHECK (statut IN (
                      N'En attente',
                      N'Valide',
                      N'Echoue',
                      N'Annule'
                  )),

    CONSTRAINT CK_Virements_comptes
        CHECK (compte_source <> compte_dest)
);
GO

-- TABLE 4 : AuditLog
-- AuditLog = journal APPLICATIF : rempli par nos procedures (INSERT).
-- Il ne remplace PAS SQL Server Audit (demo 7) : celui-ci enregistre au
-- niveau serveur, meme une modification faite directement dans SSMS.
-- Note : la colonne "date" du plan s'appelle date_action.
CREATE TABLE dbo.AuditLog (
    id                INT IDENTITY(1,1)
                      CONSTRAINT PK_AuditLog PRIMARY KEY,

    utilisateur       SYSNAME NOT NULL
                      CONSTRAINT DF_AuditLog_utilisateur
                      DEFAULT SUSER_SNAME(),

    action            NVARCHAR(200) NOT NULL,

    date_action       DATETIME2(0) NOT NULL
                      CONSTRAINT DF_AuditLog_date
                      DEFAULT SYSDATETIME(),

    -- Table concernee par l'action (ex : Comptes)
    table_concernee   SYSNAME NULL,

    -- Id de l'enregistrement concerne (ex : id du compte)
    id_enregistrement INT NULL,

    -- Valeur avant / apres la modification
    ancienne_valeur   NVARCHAR(MAX) NULL,
    nouvelle_valeur   NVARCHAR(MAX) NULL
);
GO

-- 4) Index sur les cles etrangeres -------------------------------------
-- SQL Server ne cree pas automatiquement d'index sur les FK.
-- Ces index facilitent les recherches et les jointures.

CREATE NONCLUSTERED INDEX IX_Comptes_client_id
ON dbo.Comptes(client_id);
GO

CREATE NONCLUSTERED INDEX IX_Virements_compte_source
ON dbo.Virements(compte_source);
GO

CREATE NONCLUSTERED INDEX IX_Virements_compte_dest
ON dbo.Virements(compte_dest);
GO

-- 5) Insertion des donnees de test -------------------------------------

-- Clients fictifs
INSERT INTO dbo.Clients (nom, CIN, email) VALUES
    (N'Yassine El Amrani', N'AB123456', N'yassine.elamrani@example.com'),
    (N'Salma Benali',      N'BK234567', N'salma.benali@example.com'),
    (N'Omar Tazi',         N'CD345678', N'omar.tazi@example.com'),
    (N'Khadija Idrissi',   N'EE456789', N'khadija.idrissi@example.com'),
    (N'Mehdi Alaoui',      N'FH567890', N'mehdi.alaoui@example.com');
GO

-- Comptes fictifs
-- Les soldes sont les soldes APRES les virements valides de l'historique.
-- Un virement ne cree ni ne detruit d'argent : le total de la banque
-- reste constant (66400 DH). C'est le controle utilise dans les demos.
--
--   Compte 1 : 1000                (aucun virement valide)
--   Compte 2 : 5000 + 1500  = 6500
--   Compte 3 : 2500 + 200   = 2700
--   Compte 4 : 12000 - 200 - 500 = 11300
--   Compte 5 : 30000               (aucun virement)
--   Compte 6 : 800 + 500    = 1300
--   Compte 7 : 15000 - 1500 = 13500
--   Compte 8 : 100                 (aucun virement)
--
-- Le virement echoue (3 vers 1, 100 DH) ne modifie aucun solde.
-- Le compte 1 (1000 DH) sert aux demos de lost update.
-- Les comptes 1 et 2 servent aux demos de deadlock.

INSERT INTO dbo.Comptes (client_id, solde, type) VALUES
    (1,  1000.00, N'Courant'),   -- compte 1
    (1,  6500.00, N'Epargne'),   -- compte 2
    (2,  2700.00, N'Courant'),   -- compte 3
    (3, 11300.00, N'Courant'),   -- compte 4
    (3, 30000.00, N'Epargne'),   -- compte 5
    (4,  1300.00, N'Courant'),   -- compte 6
    (5, 13500.00, N'Courant'),   -- compte 7
    (5,   100.00, N'Epargne');   -- compte 8
GO

-- Historique des virements
INSERT INTO dbo.Virements
    (compte_source, compte_dest, montant, statut)
VALUES
    (4, 3,  200.00, N'Valide'),
    (4, 6,  500.00, N'Valide'),
    (7, 2, 1500.00, N'Valide'),
    (3, 1,  100.00, N'Echoue');
GO

-- Journal applicatif initial
INSERT INTO dbo.AuditLog (action)
VALUES (N'Creation de la base BankSecure et chargement des donnees de test');
GO

-- 6) Verification -------------------------------------------------------

PRINT N'BankSecure cree avec succes.';

-- Nombre de lignes dans chaque table
SELECT N'Clients' AS [table], COUNT(*) AS lignes
FROM dbo.Clients

UNION ALL

SELECT N'Comptes', COUNT(*)
FROM dbo.Comptes

UNION ALL

SELECT N'Virements', COUNT(*)
FROM dbo.Virements

UNION ALL

SELECT N'AuditLog', COUNT(*)
FROM dbo.AuditLog;

-- Soldes
SELECT
    id,
    client_id,
    solde,
    type
FROM dbo.Comptes
ORDER BY id;

-- Controle d'integrite : un virement ne change jamais le total de la banque.
-- Resultat attendu : 66400.00
SELECT SUM(solde) AS total_banque
FROM dbo.Comptes;

-- Historique des virements
SELECT
    id,
    compte_source,
    compte_dest,
    montant,
    statut,
    date_virement
FROM dbo.Virements
ORDER BY id;

-- Journal applicatif
SELECT *
FROM dbo.AuditLog;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO