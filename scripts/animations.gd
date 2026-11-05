# scripts/animations.gd
extends Node

var oldman: Node3D
var jade: Node3D

func _ready() -> void:
    # REMPLACE "/root/Main/Object0012" PAR LE VRAI CHEMIN QUE TU AS COPIÉ
    oldman = get_node("/root/Main/Object001/Object0012")
    jade = get_node("/root/Main/Jade")
    
    print("✅ Ready : Oldman=", oldman, " Jade=", jade)

func play_n1_animation() -> void:
    print("🎬 play_n1_animation lancée !")
    
    # Vérifie que les nœuds existent
    if not oldman or not jade:
        print("❌ ERREUR : Oldman ou Jade introuvable !")
        return

    var jade_pos = jade.global_position
    
    var tween = create_tween()
    
    # Oldman se rapproche (grab)
    # On déplace Oldman vers la position de Jade
    tween.tween_property(oldman, "global_position:y", jade_pos.y - 0.5, 0.5)
    tween.tween_property(oldman, "global_position:x", jade_pos.x, 0.5)
    await tween.finished
    
    # Oldman baisse la tête (kiss)
    # On essaie de trouver un os "head" ou on bouge le corps entier
    var head_node = oldman.get_node_or_null("head")
    
    if head_node:
        # Si l'os "head" existe, on bouge lui
        var head_jade = jade.get_node_or_null("head")
        if head_jade:
            tween = create_tween()
            tween.tween_property(head_node, "global_position:y", head_jade.global_position.y + 0.1, 0.5)
            tween.tween_property(head_node, "global_position:x", head_jade.global_position.x, 0.5)
            await tween.finished
    else:
        # Si pas d'os "head", on bouge tout le corps d'Oldman vers Jade (pour simuler le kiss)
        print("⚠️ Pas d'os 'head' trouvé, on bouge tout le corps")
        tween = create_tween()
        tween.tween_property(oldman, "global_position:y", jade_pos.y + 0.2, 0.3)
        await tween.finished

func break_n1_animation() -> void:
    print("🚨 break_n1_animation lancée !")
    if not jade:
        return
        
    var tween = create_tween()
    tween.tween_property(jade, "global_position:x", jade.global_position.x - 0.5, 0.3)
    tween.tween_property(jade, "global_position:y", jade.global_position.y, 0.3)
    await tween.finished