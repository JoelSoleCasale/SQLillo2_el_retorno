# SQLillo2_el_retorno

## 1. Presentation of the problem

The problem we are faced with is the creation of a bot that is capable of playing the game proposed by the company [Capchase](https://www.capchase.com/about) for HackUPC 2023: [SQLillo Royale](http://royale.sqlillo.com/). The rules of the game are explained on their website, but basically it consists of controlling a bot that can move, shoot, melee attack and dash, with certain cooldowns. The goal is to be the last one standing.

## 2. Proposed solution

### 2.1. Moving around the map

Our first priority was to be able to move around the map. The problem is that there are infinite posibilities (all directions are allowed). We decided to approach this problem by selecting a set of N directions equispaced from each other on the unit circle. Then, we assign to each point a score that measures "how good" is that direction. Then, we choose the one with the highest score. This way, we can move around the map in a more or less intelligent way that can be adapted at every instant and that is not too computationally expensive.

### 2.2. Score function

The idea of measuring the "goodness" of a direction is not easy to define. There are different criteria that can be used. We decided to take into account the following:

- **The distance to the nearest enemy**. We want to be as far as possible from the enemies in order to survive. Specially important if we are close to melee range.

- **The ring of fire**. We want to be inside the ring of fire in order to not getting hurt. We also don't want to be too close to the ring of fire, because we could get trapped.

- **Dash penalty**. Dash offers the oportunity to move faster, but it has a cooldown. We want to use it wisely, only when it is really necessary.

- **Avoiding bullets**. We have limited health, so avoiding bullets is a priority.

- **Walls**. Being close to a wall implies that we have less directions to choose from. Even worse for corners. We want to avoid this if possible.

Each of these score criteria returns some metric to evaluate the goodness of a direction (for example, the distance to the nearest enemy for the first, or an indicator function for the ring of fire for the second). Then, we combine them with some weights to obtain the final score. The weight adjustemnt will be explained later on [Hyperparameter Adjustement](#24-hyperparameters-adjustement)

## 2.3. Attacking

## 2.4. Hyperparameters adjustement
