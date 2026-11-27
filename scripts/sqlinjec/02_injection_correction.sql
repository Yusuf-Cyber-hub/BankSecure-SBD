
-- Professeur : Ali KARTIT
-- DEMO 3 : SQL INJECTION - CORRECTION
-- Protection avec sp_executesql et parametres

USE BankSecure;
GO

SET NOCOUNT ON;

-- =========================================================
-- ETAPE 1 : Definition de la requete securisee
-- =========================================================

-- MODIFICATION :
-- Les entrees utilisateur sont remplacees par des parametres.
-- SQL Server distingue le code SQL des donnees utilisateur.

DECLARE @sql NVARCHAR(MAX);

SET @sql = N'
    SELECT id, nom, CIN, email
    FROM dbo.Clients
    WHERE email = @email
      AND CIN = @cin;
';

-- Definition des types des parametres
DECLARE @parametres NVARCHAR(200);

SET @parametres =
    N'@email NVARCHAR(150), @cin NVARCHAR(20)';


-- =========================================================
-- ETAPE 2 : Test avec des donnees normales
-- =========================================================

DECLARE @email NVARCHAR(150);
DECLARE @cin NVARCHAR(20);

SET @email = N'yassine.elamrani@example.com';
SET @cin = N'AB123456';

PRINT N'TEST 1 : Recherche normale';

EXEC sys.sp_executesql
    @sql,
    @parametres,
    @email = @email,
    @cin = @cin;


-- =========================================================
-- ETAPE 3 : Test avec le meme Payload malveillant
-- =========================================================

-- MODIFICATION :
-- Le payload est transmis comme une simple valeur.
-- Il ne sera pas execute comme du code SQL.

SET @email = N''' OR 1=1 --';
SET @cin = N'AB123456';

PRINT N'TEST 2 : Tentative de SQL Injection';

EXEC sys.sp_executesql
    @sql,
    @parametres,
    @email = @email,
    @cin = @cin;


-- =========================================================
-- ETAPE 4 : Verification
-- =========================================================

PRINT N'Verification de la protection :';

SELECT
    N'La requete est parametree' AS protection,
    N'Le payload est traite comme une donnee' AS resultat;

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO
