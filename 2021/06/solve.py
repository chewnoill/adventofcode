import fileinput
# echo "3,4,3,1,2" > input
# python solve.py < input
old_world = [int(num) for num in fileinput.input()[0].split(',')]

number_of_days = 80

world = old_world
for x in range(number_of_days):
  newWorld = []
  for age in world:
      if age == 0:
        newWorld += [6,8]
      else:
        newWorld += [age-1]
  world = newWorld

print(len(world))
# 5934


from functools import reduce

empty_world = reduce(( lambda acc, age: ({**acc, age: 0})), [age for age in range(9)], {})

world = reduce((lambda acc,age: ({**acc, age: acc[age]+1})), old_world, empty_world)

number_of_days = 256

for x in range(number_of_days):
  newWorld = empty_world
  for age in range(9):
      next_population = 0
      if age <= 7:
        next_population = world[age+1]
      if age == 8 or age == 6:
        next_population += world[0]
      newWorld[age] = next_population
  world = newWorld


print(reduce(( lambda acc, count: acc + count), world.values()))

