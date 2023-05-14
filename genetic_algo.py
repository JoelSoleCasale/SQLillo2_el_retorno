import random
import os
import time
from pprint import pprint


def timer_decorator(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        execution_time = end_time - start_time
        print(f"Execution time of {func.__name__}: {execution_time} seconds")
        return result
    return wrapper


# Genetic Algorithm Parameters
population_size = 30
mutation_rate = 0.01
tournament_size = 4
elite_size = 3
num_generations = 30

# Define the range of each parameter
parameter_ranges = {
    'LAMB': (50, 150),
    'DASH_PEN': (-300, -50),
    'MELE_PEN': (-300, -50),
    # 'SHOOT_RANGE': (16, 16),
    # 'SAFE_RANGE': (27, 60),
    # 'MARGIN': (0.7, 0.95),
    # 'HIT_PENALTY_1': (-10**5, -1000),
    # # 'HIT_RADIUS_1': (1, 1.5),
    # 'HIT_PENALTY_2': (-10**4, -500),
    # 'HIT_RADIUS_2': (1.1, 2.2),
    # 'COLUMN_PENALTY': (0, 10),
    # 'WALL_MARGIN': (0, 7),
    'WALL_PENALTY': (-200, -10),
}

# Generate an initial population of random individuals


def generate_individual():
    individual = {}
    for param, (lower, upper) in parameter_ranges.items():
        individual[param] = random.uniform(lower, upper)
    return individual


def generate_script(individual, index):
    script_base = open("sample_code.lua", "r")
    script = open("./temp_files/script" + str(index) + ".lua", "w")
    # add the parameter lines at the beginning of the script
    for param, value in individual.items():
        script.write("local " + param + " = " + str(value) + "\n")
    # add the rest of the script
    for line in script_base:
        script.write(line)
    script.close()
    script_base.close()

    return "temp_files/script" + str(index) + ".lua"


@timer_decorator
def run_tournament(pop):
    # generate a script for each individual
    scripts_txt = ""
    for i in range(len(pop)):
        # pop[i]["WALL_MARGIN"] = round(pop[i]["WALL_MARGIN"])
        scripts_txt += generate_script(pop[i], i+1) + " "
    # run the tournament
    command = "docker run -v $(pwd)/temp_files:/temp_files --rm -it tarasyarema/sqlillo "
    # run the command
    command += scripts_txt + " | grep DEAD > temp_files/results.txt"
    result = os.popen(command).read()
    # remove the scripts
    for i in range(len(pop)):
        os.remove("./temp_files/script" + str(i+1) + ".lua")

    # parse the results
    results = open("./temp_files/results.txt", "r")
    fitness_values = [population_size for _ in range(len(pop))]
    i = 0
    for line in results:
        i += 1
        fitness_values[int(''.join(filter(str.isdigit, line)))] = i
    results.close()
    return fitness_values


# Evaluate the fitness of each individual using the tournament selection
def evaluate_population(population):
    ranked_population = []
    # Assuming run_tournament takes the entire population as input
    fitness_values = run_tournament(population)

    for i, individual in enumerate(population):
        fitness = fitness_values[i]
        ranked_population.append((individual, fitness))

    ranked_population.sort(key=lambda x: x[1], reverse=True)
    return ranked_population


# Select parents for crossover using tournament selection


def select_parents(population):
    parents = []
    for _ in range(population_size - elite_size):
        tournament = random.sample(population, tournament_size)
        tournament.sort(key=lambda x: x[1], reverse=True)
        winner = tournament[0][0]
        parents.append(winner)
    return parents

# Perform crossover between two parents to create a new individual


def crossover(parent1, parent2):
    child = {}
    for param in parameter_ranges.keys():
        # Perform uniform crossover
        if random.random() < 0.5:
            child[param] = parent1[param]
        else:
            child[param] = parent2[param]
    return child

# Mutate an individual by randomly perturbing its parameters


def mutate(individual):
    mutated_individual = {}
    for param, value in individual.items():
        if random.random() < mutation_rate:
            lower, upper = parameter_ranges[param]
            mutated_value = value + random.uniform(lower, upper)
            mutated_value = max(lower, min(upper, mutated_value))
            mutated_individual[param] = mutated_value
        else:
            mutated_individual[param] = value
    return mutated_individual

# Create the next generation through selection, crossover, and mutation


def create_next_generation(population):
    ranked_population = evaluate_population(population)
    next_generation = [individual for individual,
                       _ in ranked_population[:elite_size]]
    parents = select_parents(ranked_population)
    for i in range(population_size - elite_size):
        parent1 = random.choice(parents)
        parent2 = random.choice(parents)
        child = crossover(parent1, parent2)
        mutated_child = mutate(child)
        next_generation.append(mutated_child)
    return next_generation


def main():
    population = [generate_individual() for _ in range(population_size)]
    # Run the genetic algorithm
    for generation in range(num_generations):
        print("Generation:", generation)
        population = create_next_generation(population)
        # show the best individual parameters with pprint
        pprint(population[0])
        print()

    # Get the 5 best individuals from the final population
    ranked_population = evaluate_population(population)
    print("Best Individuals:")
    for i in range(5):
        individual, fitness = ranked_population[i]
        pprint("Individual:", individual)
        print("Fitness:", fitness)
        print()


if __name__ == '__main__':
    # run_tournament(population)
    main()
