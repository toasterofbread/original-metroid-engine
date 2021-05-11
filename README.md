# Metroid Engine

## Changelog:



## 30 June 2020 (day 3) 

- Added crouching
- Added turnaround animation, hurtbox, and beam origin points for crouching

- Readded weapon selection
- Added weapon cancelling
- The HUD now adds icons for available weapons
- The HUD removes digit sprites for weapons with no set amount
- Weapon selections are shown in the HUD
- Weapon selection is automatically cancelled when the selected weapon depletes

- Added missiles and super missiles
- Added screen shake on super missile impact

- Added white flash effect on Samus when she takes damage



## 1 July 2020 (day 4)

- Added right facing versions of all of Samus's current sprites, as opposed to flipping the left facing sprite
- Made Samus take knockback in the opposite direction when hit by an enemy

- Made it easier for Samus to cancel into a run while crouching
- Fine-tuned Samus's jump height, run speed, etc to more closely match Super Metroid (still needs work)



## 2 July 2020 (day 5)

- Added title screen
- Added intro cinematic

- Improved how Samus handles turning animations to reduce bugs and improve readability


## 3 July 2020 (day 6)

- Added morph ball
- Added bomb (damages enemies and moves Samus up when she is in morph ball form)
- Added a dynamic raycaster to Samus to prevent her from leaving morph ball/crouch mode if there is a ceiling above her

- Added doors (beam, missile, super missile, power bomb, and locked types)
- Began work on door transition animation

- Improved how Samus's collision box is applied when her animation changes to prevent clipping into the floor



## 4 July 2020 (day 7)

- Completed the door transition animation
- Added a GLOBAL script

