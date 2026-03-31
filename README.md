# League of SN — Analyse des performances dans League of Legends

<p align="center">
  <img src="assets/league-of-sn.png" width="400"/>
</p>

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

Pour répondre à cette question, nous adoptons une démarche progressive d’exploration et d’analyse des données, structurée en plusieurs parties.

---

#### 1. Exploration des données

Dans un premier temps, nous réalisons une analyse descriptive du dataset afin de mieux comprendre sa structure, la nature des variables et leur distribution. Cette étape permet d’identifier d’éventuelles anomalies et de préparer les analyses suivantes.

Exemples de questions :

- Quelle est la distribution des variables principales (kills, deaths, gold, cs, damage) ?
- La variable `win` est-elle équilibrée entre victoires et défaites ?
- Certaines variables présentent-elles des valeurs atypiques ou extrêmes ?

---

#### 2. Performance individuelle et victoire

Nous analysons l’impact des performances individuelles sur la probabilité de victoire afin d’identifier les variables les plus discriminantes.

Exemples de questions :

- Les joueurs gagnants ont-ils en moyenne plus de kills que les perdants ?
- Les joueurs perdants ont-ils davantage de deaths ?
- Le KDA est-il plus élevé chez les joueurs gagnants ?
- Le gold gagné est-il plus élevé chez les joueurs qui gagnent ?
- Le CS est-il plus élevé chez les joueurs gagnants ?
- Le damage infligé est-il un bon indicateur de victoire ?

---

#### 3. Relations entre variables

Nous étudions les liens entre les différentes variables du dataset afin de mieux comprendre les interactions entre les indicateurs de performance.

Exemples de questions :

- Le gold est-il corrélé au CS ?
- Le damage infligé est-il corrélé au nombre de kills ?
- Le KDA est-il corrélé à la victoire ?
- Le nombre de deaths impacte-t-il plus la victoire que les kills ?

---

#### 4. Analyse par rôle

Nous comparons les performances selon les rôles joués afin d’identifier des différences de style de jeu et d’impact sur la victoire.

Exemples de questions :

- Certains rôles ont-ils un meilleur winrate que d’autres ?
- Les rôles présentent-ils des profils de performance différents (kills, vision, gold, damage) ?
- Les performances économiques et offensives varient-elles selon le rôle ?

---

#### 5. Analyse par champion

Nous analysons les champions afin d’identifier d’éventuelles tendances liées au choix du personnage.

Exemples de questions :

- Quels sont les champions les plus joués dans le dataset ?
- Quels champions ont le meilleur winrate (avec un nombre minimum de matchs) ?
- Certains champions présentent-ils des profils statistiques spécifiques ?

---

#### 6. Modélisation

Enfin, nous cherchons à synthétiser les résultats via un modèle prédictif.

Exemples de questions :

- Peut-on prédire la victoire à partir des variables disponibles ?

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