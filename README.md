# BankSecure : Securite des bases de donnees transactionnelles

Projet SBD | Groupe 7 | Professeur : Ali KARTIT | Presentation : 01/12/2026

Cas d'etude : une banque fictive (BankSecure) sous **SQL Server 2025 Enterprise Developer** avec **SSMS 22**.

## Contenu du depot

| Dossier | Contenu |
|---|---|
| `scripts/` | Scripts SQL de toutes les demos |
| `captures/` | Captures d'ecran (chacune contient « Professeur : Ali KARTIT ») |
| `rapport/` | Rapport Word (15 a 20 pages) |
| `powerpoint/` | Presentation |

## Demarrage rapide

1. Cloner le depot : `git clone <url-du-depot>`
2. Ouvrir SSMS 22 et se connecter a `localhost` (cocher *Trust Server Certificate*).
3. `File > Open > File` puis `scripts/00_creation_BankSecure.sql`.
4. Cliquer **Execute** (F5).
5. Dans l'Explorateur d'objets : clic droit sur *Databases > Refresh*. La base **BankSecure** apparait.

Le script est rejouable : il supprime puis recree la base. C'est aussi la remise a zero entre deux demos.

## Organisation des scripts

| Fichier | Responsable |
|---|---|
| `00_creation_BankSecure.sql` | Membre 1 |
| `01_transactions.sql` | Membre 1 |
| `02_injection_*.sql` | Membre 2 |
| `03_concurrence_*.sql`, `04_deadlock_*.sql` | Membre 3 |
| `05_roles.sql`, `06_audit.sql`, `07_backup.sql` | Membre 4 |

## Regles du groupe

- Chacun ne modifie que **ses propres fichiers**.
- Premiere ligne de chaque script : `-- Professeur : Ali KARTIT`, et `USE BankSecure;` juste apres.
- Un script doit pouvoir etre rejoue sans erreur.
- **Aucun mot de passe reel** dans le depot (le mot de passe `sa` reste local).
- Ne pas changer la structure des 4 tables sans prevenir Membre 1.
- Avant de commencer : `git pull`. Apres avoir travaille : `git add .`, `git commit -m "message"`, `git push`.
