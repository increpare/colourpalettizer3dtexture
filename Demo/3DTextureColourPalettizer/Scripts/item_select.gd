extends ItemList

@export var palettizer:Palettizer

func _ready() -> void:
	self.select(0,true)
	
func _on_item_selected(index: int) -> void:
	if index==0:
		%TextureRect.visible=false
		%CanvasLayer.visible=false
		return
		
	%TextureRect.visible=true	
	%CanvasLayer.visible=true
	print("item selected ",index)
	var name = self.get_item_text(index)
	var resource_string="res://Addons/3DTextureColourPalettizer/Palettes/"+name+".png"
	print("item name ",name)
	var loaded_image : Texture2D = load(resource_string)
	palettizer.palette_source = loaded_image
	%TextureRect.texture = loaded_image
