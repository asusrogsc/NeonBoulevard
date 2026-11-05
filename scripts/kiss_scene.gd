class_name KissScene
extends RefCounted
## Le baiser : les os sont tenus par une vraie animation (kiss_anim.gd), évaluée dans
## ModelRig.apply_pose. Cette classe ne gère plus que le placement et la durée.

const DUR := 3.0
## écart entre son bassin et le centre du héros : il se place du côté de la tête,
## jamais côté pieds (le héros est allongé, tête vers -face)
const GAP := 22.0


## Décalage [x signé par face, z] du personnage qui embrasse, à l'instant t.
static func place(_t: float) -> Array:
	return [-GAP, 0.0]