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

Each of these score criteria returns some metric to evaluate the goodness of a direction (for example, the distance to the nearest enemy for the first, or an indicator function for the ring of fire for the second). Then, we combine them with some weights to obtain the final score. The weight adjustemnt will be explained later on [Hyperparameter Adjustement](#25-hyperparameters-adjustement)

## 2.3 Dodging bullets

## 2.4. Attacking

This is the less important part of out strategy.

A good moving strategy in most cases is good enough to survive up to the top 5, even the top 3, but in order to win the game we need to be able to attack. We have two options: melee attack and shooting. Shoothing is, in general, not that usefull. As we discused in [Dodging bullets](#23-dodging-bullets), in most cases it is possible to dodge bullets by moving. 

Given that, we are only using shoots in two cases:

1. When the enemy is so far away that we can shot and have time to reload before he reaches us.

2. When the enemy is close enough to have a hard time dodging the bullets.

As for melee attacks, our approach is even simpler: is there is an enemy in melee range, we attack if possible. Otherwise, we don't.

## 2.5. Hyperparameters adjustement

Trying to find the best hyperparameters for our strategy is a hard task. We have a lot of parameters to adjust, and the space of possible values is huge.

Our approach to this problem is to use a genetic algorithm. We define a population of strategies, and we let them play against each other. Then, we select the best ones and we combine them to create new strategies. We repeat this process until we find a good strategy.

Each strategy is equal to the rest, except for the hyperparameters. We define a set of hyperparameters, and we assign a value to each of them. Then, we combine them to create a strategy. 

This, however, had two main problems:

1. We needed a lot of computing power to run the genetic algorithm. 

2. The genetic algotihtm is only compiting against itself, so it is not guaranteed that the best strategy is good enough to win the game against other players.
