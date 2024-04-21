# Table of Contents
- [About](#about)
- [Results](#results)
- [Usages](#usage)
- [Dependencies](#dependencies)
- [Development Resources](#development-resources)


## About
Developed for CPSC470 Senior Project

This game is built around an interactable 3x3 Rubik's Cube. Includes a solver algorithm that implements the Beginner's Method and provides detailed and interactable instructions for solving the cube in any state using an Iterative-Deepening A* Search Algorithm

## Results
The Rubik's Cube solver was tested on 1,000 scrambles of 25 moves each. On average, the solver can compute a solve in 3.64 seconds using about 109 moves.

![image](https://github.com/MayorGnarwhal/rubikscube/assets/46070329/964d01b6-bd9a-4027-9aa3-7cbfe6cafa2f)


## Usage
The game is freely playable on the Roblox platform at https://www.roblox.com/games/16071438266

A copy of the game can be downloaded in the form of an .rbxl file can be downloaded from the [lastest release](https://github.com/MayorGnarwhal/rubikscube/releases).
- Open in Roblox Studio through File > Open From File and selecting .rbxl file


## Dependencies
- [Parallel Scheduler](https://devforum.roblox.com/t/parallel-scheduler-parallel-lua-made-easy-and-performant/2535929) by [@Tomi1231](https://www.roblox.com/users/79690730/profile)
- [Slider Service](https://devforum.roblox.com/t/sliderservice-create-easy-and-functional-sliders/1597785) by [@Krystaltinan](https://www.roblox.com/users/418823949/profile)
- [Collect](https://github.com/MayorGnarwhal/Collect)
- [Tween](https://github.com/MayorGnarwhal/Tween)


## Development Resources
- Implementation of Iterative-Deepening A* Search Algorithm based on implementation of [DeepCubeA](https://deepcube.igb.uci.edu/static/files/SolvingTheRubiksCubeWithDeepReinforcementLearningAndSearch_Final.pdf) by McAleer et. al.
- Developed in [Roblox Studio](https://create.roblox.com/landing)
- Exported to GitHub through [Rojo](https://rojo.space/) and [rblx-to-rojo](https://github.com/rojo-rbx/rbxlx-to-rojo)
