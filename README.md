# League of SN — Analyse des performances dans League of Legends

## Introduction

### Données

Dans le cadre de ce projet, nous avons choisi d’analyser des données issues du jeu vidéo **League of Legends**. Ce choix s’inscrit dans une volonté de travailler sur un sujet pertinent, actuel et motivant, permettant d’étudier des problématiques concrètes liées à la performance et à la prise de décision.

Le jeu de données a été construit à partir de l’API officielle Riot Games. Il contient des informations sur des parties classées (ranked) récentes, issues de joueurs de haut niveau (Challenger, Grandmaster, Master).

Le dataset est structuré de la manière suivante :

- **Nombre d’observations** : 1690 lignes  
- **Nombre de variables totales** : 21 variables  
- **Nombre de variables réellement exploitables** : **18 variables**  
- **Format** : CSV  
- **Structure** : 1 ligne = 1 joueur dans une partie  

Les données sont stockées dans le dossier `/data/`.

Ce dataset a été choisi car :
- il est suffisamment volumineux pour permettre des analyses pertinentes.
- il contient des variables variées (numériques, catégorielles, binaires).  
- il permet de répondre à des questions concrètes sur la performance en jeu.
- il est facilement manipulable avec les outils R étudiés en cours. 

---

### Description des variables

| Variable | Type | Description | Utilisée |
|----------|------|------------|----------|
| match_id | Identifiant | Identifiant unique de la partie | ❌ |
| game_creation | Temporel | Date de création de la partie | ❌ |
| game_duration | Numérique | Durée de la partie (en secondes) | ✔️ |
| queue_id | Catégorielle | Type de partie | ✔️ |
| champion | Catégorielle | Champion joué | ✔️ |
| role | Catégorielle | Rôle du joueur (TOP, JUNGLE, MIDDLE, BOTTOM, UTILITY) | ✔️ |
| lane | Catégorielle | Position sur la carte | ⚠️ (peu fiable) |
| win | Binaire | Résultat (1 = victoire, 0 = défaite) | ✔️ |
| kills | Numérique | Nombre de kills | ✔️ |
| deaths | Numérique | Nombre de morts | ✔️ |
| assists | Numérique | Nombre d’assists | ✔️ |
| gold | Numérique | Gold gagné | ✔️ |
| cs | Numérique | Nombre de sbires tués | ✔️ |
| vision | Numérique | Score de vision | ✔️ |
| damage | Numérique | Dégâts infligés | ✔️ |
| damage_taken | Numérique | Dégâts subis | ✔️ |
| wards_placed | Numérique | Balises placées | ✔️ |
| wards_killed | Numérique | Balises détruites | ✔️ |
| champ_level | Numérique | Niveau du champion | ✔️ |
| puuid | Identifiant | Identifiant du joueur | ❌ |
| kda | Numérique | (kills + assists) / deaths | ✔️ |

---

### Variables exploitées

Afin de respecter les consignes du projet (10 à 20 variables pertinentes), nous avons effectué une sélection des variables.

Les variables suivantes ont été exclues de l’analyse :
- `match_id` → identifiant technique  
- `puuid` → identifiant joueur  
- `game_creation` → non pertinent pour l’analyse  

La variable `lane` est conservée à titre informatif mais sera peu ou pas utilisée en raison de possibles incohérences avec la variable `role`.

Ainsi, l’analyse repose sur **18 variables réellement exploitables**, ce qui correspond parfaitement aux attentes du projet.

---

### Plan d’analyse

L’objectif du projet est de répondre à la problématique suivante :

> **Quels indicateurs de performance individuelle influencent le plus la victoire dans une partie de League of Legends ?**

L’analyse sera structurée en plusieurs étapes.

#### 1. Exploration des données
- Distribution des variables principales  
- Analyse de l’équilibre victoire/défaite  

#### 2. Performance individuelle
- Comparaison des kills, deaths, assists  
- Analyse du gold, du CS et du damage  
- Étude du KDA  

#### 3. Relations entre variables
- Corrélation gold / CS  
- Corrélation damage / kills  
- Analyse du lien avec la victoire  

#### 4. Analyse par rôle
- Winrate par rôle  
- Différences de style de jeu  

#### 5. Analyse par champion
- Champions les plus joués  
- Winrate (avec filtre)  

#### 6. Modélisation
- Régression logistique  
- Identification des variables influentes  

---

### Limites du dataset

- Données issues uniquement de joueurs haut niveau  
- Analyse centrée sur la performance individuelle  
- Absence de données macro (draft, stratégie, timeline)  

---

## Conclusion de la proposition

Ce projet vise à exploiter un jeu de données réel afin de mettre en œuvre les compétences acquises en visualisation et analyse de données avec R.

L’approche repose sur une démarche :
- exploratoire  
- progressive  
- critique  

L’objectif est de produire une analyse cohérente, argumentée et pertinente à partir des données disponibles.