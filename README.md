# League of SN : Exploration des dynamiques de performance dans League of Legends  
Projet IF36 : Université de Technologie de Troyes

<p align="center">
  <img src="assets/league-of-sn.png" width="700"/>
</p>

---

## Introduction

### Données

Notre projet repose sur l’exploitation de deux sources de données complémentaires issues de League of Legends. L’objectif est de croiser une analyse à deux niveaux :

- une vision **individuelle** avec les données soloQ  
- une vision **collective et stratégique** avec les données professionnelles  

Cette approche permet de construire une analyse riche et multidimensionnelle du jeu.

---

## Source principale : Riot Games API — Dataset SoloQ

Le premier dataset est issu de l’API Riot Games et contient des parties classées de joueurs de haut niveau.

- **Structure** : 1 ligne = 1 joueur dans une partie  
- **Contexte** : environnement non coordonné (soloQ)  

Variables principales :

- performance : `kills`, `deaths`, `assists`, `kda`  
- ressources : `gold`, `cs`  
- vision : `vision`, `wards_placed`, `wards_killed`  
- combat : `damage`, `damage_taken`  
- contexte : `role`, `champion`, `game_duration`  
- résultat : `win`  

Ce dataset permet d’analyser la performance individuelle.

---

## Source complémentaire : Oracle’s Elixir — Dataset professionnel

Le second dataset provient de la scène compétitive (LEC, LCK, LCS, LPL…).

- **Structure** : 1 ligne = 1 joueur dans une partie  
- **Contexte** : environnement coordonné et stratégique  

Variables principales :

- performance : `kills`, `deaths`, `assists`, `kda`  
- ressources : `gold`, `cs`  
- early game : `goldat10`, `golddiffat10`, `goldat15`, `goldat20`  
- objectifs : `dragons`, `barons`, `heralds`, `towers`  
- vision : `vision`, `wardsplaced`, `controlwardsbought`  
- équipe : `teamkills`, `damageshare`, `kill_participation`  
- contexte : `role`, `champion`, `player`, `team`, `league`  
- résultat : `win`  

Ce dataset permet une analyse macro et stratégique.

---

## Résumé du schéma de données

Nous combinons deux visions du jeu :

- soloQ → performance individuelle  
- pro → stratégie collective  

Ce contraste est au cœur de notre analyse.

---

## Plan d’analyse

Notre analyse s’articule autour de trois axes.

---

## Axe 1 — La performance individuelle en soloQ

Dans la soloQ, la performance repose principalement sur les actions individuelles. Nous cherchons donc à identifier les facteurs qui influencent directement la victoire.

### Q1 : Le KDA est-il un bon indicateur de victoire ?

Nous comparons la distribution du KDA entre joueurs gagnants et perdants à l’aide de boxplots. Cette analyse permet d’évaluer si cet indicateur reflète réellement la performance globale.

---

### Q2 : La survie influence-t-elle la victoire ?

Nous analysons la variable `deaths` afin de déterminer si limiter ses morts constitue un facteur déterminant dans l’issue des parties.

---

### Q3 : L’économie (gold) est-elle déterminante ?

Nous comparons les niveaux de gold entre joueurs gagnants et perdants afin d’évaluer l’importance de l’avantage économique individuel.

---

### Q4 : Le CS est-il un facteur clé de performance ?

Nous analysons la distribution du CS afin de mesurer l’impact du farming sur la réussite des joueurs.

---

### Q5 : Les performances sont-elles homogènes ou très variables ?

Nous utilisons des density plots pour analyser la dispersion des performances et identifier la variabilité entre joueurs.

---

### Q6 : Certains rôles ont-ils un avantage structurel ?

Nous comparons les taux de victoire moyens par rôle afin d’identifier d’éventuels déséquilibres.

---

### Q7 : Les styles de jeu diffèrent-ils selon les rôles ?

Nous analysons les statistiques de combat selon les rôles afin de mettre en évidence des profils distincts.

---

## Axe 2 — La stratégie et le jeu professionnel

Le jeu professionnel repose sur une coordination d’équipe et une stratégie avancée. Nous analysons ici les facteurs macro influençant la victoire.

### Q8 : L’early game est-il déterminant ?

Nous analysons la variable `goldat10` afin d’évaluer si un bon début de partie est associé à la victoire.

---

### Q9 : L’écart de gold est-il plus pertinent que la valeur brute ?

Nous étudions `golddiffat10` afin de mesurer l’importance de l’avantage relatif entre équipes.

---

### Q10 : Les objectifs influencent-ils fortement la victoire ?

Nous analysons les dragons et barons afin d’évaluer leur rôle stratégique dans le jeu.

---

### Q11 : La vision est-elle un facteur clé ?

Nous comparons les scores de vision entre équipes gagnantes et perdantes afin d’évaluer le contrôle de la carte.

---

### Q12 : Existe-t-il des joueurs particulièrement performants ?

Nous analysons les performances individuelles afin d’identifier des joueurs dominants ou réguliers.

---

### Q13 : Certaines équipes dominent-elles statistiquement ?

Nous comparons les performances globales des équipes afin d’identifier d’éventuelles dominations.

---

### Q14 : Les styles de jeu diffèrent-ils selon les équipes ?

Nous analysons les statistiques (kills, objectifs, vision) afin d’identifier des stratégies distinctes.

---

## Axe 3 — Comparaison soloQ vs scène professionnelle

Nous comparons les deux environnements afin d’identifier leurs différences fondamentales.

### Q15 : Le niveau de performance diffère-t-il ?

Nous comparons les distributions de KDA entre soloQ et pro.

---

### Q16 : Les joueurs professionnels meurent-ils moins ?

Nous analysons les `deaths` afin d’évaluer la gestion du risque.

---

### Q17 : Les performances sont-elles plus stables en pro ?

Nous comparons la dispersion des performances afin d’évaluer la régularité.

---

### Q18 : L’impact des kills est-il différent ?

Nous analysons l’influence des kills sur la victoire dans les deux contextes.

---

### Q19 : Le gold est-il plus déterminant en soloQ ?

Nous comparons les écarts économiques entre gagnants et perdants.

---

### Q20 : Le jeu pro repose-t-il davantage sur la stratégie ?

Nous analysons l’importance des objectifs et de la vision.

---

## L’application Shiny

L’application Shiny permettra une exploration interactive des données.

Elle sera organisée en plusieurs onglets :

- SoloQ → performance individuelle  
- Pro → stratégie et analyse par équipe/joueur  
- Comparaison → différences entre environnements  

Un onglet supplémentaire permettra une analyse géographique des ligues via une carte du monde.

---

## Considérations méthodologiques

- biais de sélection (soloQ haut niveau)  
- différences structurelles entre soloQ et pro  
- absence de certaines variables (draft, communication)  

---

## Conclusion

Ce projet met en évidence deux logiques :

- soloQ → performance individuelle  
- pro → stratégie collective  

L’analyse vise à proposer une vision claire, structurée et critique des facteurs de performance.