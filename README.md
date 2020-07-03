# Metroid Engine

## Changelog:



## 30 June 2020 (day 4) 

### Added
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

### Changed
- No record
### Removed
- No record



## 1 July 2020 (day 5)

### Added
- Added right facing versions of all of Samus's current sprites, as opposed to flipping the left facing sprite
- Made Samus take knockback in the opposite direction when hit by an enemy
### Changed
- Made it easier for Samus to cancel into a run while crouching
- Fine-tuned Samus's jump height, run speed, etc to more closely match Super Metroid (still needs work)
### Removed


## 2 July 2020 (day 6)

### Added
- Added title screen
- Added intro cinematic
### Changed
- Improved how Samus handles turning animations to reduce bugs and improve readability
### Removed


## 3 July 2020 (day 7)

### Added
- Added morph ball
- Added bomb (damages enemies and moves Samus up when she is in morph ball form)
- Added dynamic raycasters to Samus to prevent her from leaving morph ball/crouch mode if there is a ceiling above her
### Changed
- Improved how Samus's collision box is applied when her animation changes to prevent clipping into the floor
### Removed