extends TileMap
# -1 casilla vacia
# 0 mina
# 1-8 casilla numero


const cell_columna := 30
const cell_fila := 30
const mine_count := int(cell_columna * cell_fila * 0.20)

var muerte := false
var cells : Array[int]
var cells_alrededor : Array[int]
var offsetCoords : Vector2i
var empeso :=false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setupboard()
	#ajusta el tamaño de la pantalla al necesario
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(cell_fila, cell_columna) * 16
	
	var scale_factor: float = minf(
		viewport_size.x / board_size.x,
		viewport_size.y / board_size.y
	)
	
	scale = Vector2.ONE * scale_factor
	
# Tablero vacío
func setupboard() -> void:
	for y in range(cell_columna):
		for x in range(cell_fila):
			set_cell(0, Vector2i(x,y), 0, Vector2i(0,0))
			cells.append(-1)
#elnombrer
func setupmines(avoid : Vector2i) -> void:
	for i in range(mine_count):
		cells[i] = 0
	
	cells.shuffle()
	
	# previene instalose
	while getSurroundingCells(avoid, 5).has(0):
		cells.shuffle()
		
		#ponemos las casillass de numeros
	for y in range(cell_columna):
		for x in range(cell_fila):
			# For each cell at x, y
			if not cells[getCellIndex(Vector2i(x, y))] == 0:
				var mineCount := 0
				for i in getSurroundingCells(Vector2i(x, y), 3):
					if i == 0:
						mineCount += 1
				if mineCount > 0:
					cells[getCellIndex(Vector2i(x, y))] = mineCount


# Detectar Clicks en las cells
func _input(event: InputEvent) -> void:
	if muerte==false:
		if empeso==false:
			empeso==true
			
		if event.is_action_pressed("ShowMeYourTrueForm"):
			var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
			# pa que no se puedan clickear banderas
			if getAtlasCoords(cellAtMouse) != Vector2i(1, 0):
				if cells.has(0):
					trueForm(cellAtMouse)

			
			# si el clickea una mina, shinu
					if cells[getCellIndex(cellAtMouse)] == 0:
						muerte = true
						showmeyalltrueforms(cellAtMouse)
				else:
					setupmines(cellAtMouse)
					trueForm(cellAtMouse)
			
		if event.is_action_pressed("flag"):
			var cellAtMouse : Vector2i = local_to_map(get_local_mouse_position())
			# If unrevealed cell, place flag. If flagged cell, make unrevealed
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				set_cell(0, cellAtMouse, 0, Vector2i(1, 0))
			elif getAtlasCoords(cellAtMouse) == Vector2i(1, 0):
				set_cell(0, cellAtMouse, 0, Vector2i(0, 0))
# Evento cuando click
func trueForm(cellCoords : Vector2i) -> void:
	var cellIndex : int
	cellIndex = getCellIndex(cellCoords)
	
	var atlasCoords : Vector2i
	match cells[cellIndex]:
		-1: atlasCoords = Vector2i(3,0) # Empty cell
		0: atlasCoords = Vector2i(0,3) # Mine
		1: atlasCoords = Vector2i(0, 1) # Number cells
		2: atlasCoords = Vector2i(1, 1)
		3: atlasCoords = Vector2i(2, 1)
		4: atlasCoords = Vector2i(3, 1)
		5: atlasCoords = Vector2i(0, 2)
		6: atlasCoords = Vector2i(1, 2)
		7: atlasCoords = Vector2i(2, 2)
		8: atlasCoords = Vector2i(3, 2)
	
	set_cell(0, cellCoords, 0, atlasCoords)
# solo muestra las vacías
	if cells[cellIndex] == -1:
		trueformalrededor(cellCoords)
		#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa


# convierte la coordenada del click del mouse en una posición del array de las casillas
func getCellIndex(cellCoords : Vector2i) -> int:
	if cellCoords.x < cell_fila and cellCoords.y < cell_columna:
		if cellCoords.x >= 0 and cellCoords.y >= 0:
			return cellCoords.y * cell_fila + cellCoords.x
		else:
			return -1
	else:
		return -1
		

# Don't set size too high or it will lag/crash the game
func getSurroundingCells(cellCoords : Vector2i, size : int) -> Array[int]:
	cells_alrededor = []
	for y in range(-1, size-1):
		for x in range(-1, size-1):
			offsetCoords = cellCoords + Vector2i(x, y)
			if getCellIndex(offsetCoords) > -1:
				cells_alrededor.append(cells[getCellIndex(offsetCoords)])
			else:
				cells_alrededor.append(-1)
	return cells_alrededor

func trueformalrededor(cellCoords : Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			offsetCoords = cellCoords-Vector2i(x , y)
			if getCellIndex(offsetCoords) > -1:
					if getAtlasCoords(offsetCoords) == Vector2i(0,0) or getAtlasCoords(offsetCoords) == Vector2i(1,0):
						trueForm(offsetCoords)

func getAtlasCoords(cellCoords : Vector2i) -> Vector2i:
	return get_cell_atlas_coords(0, cellCoords)
	
func showmeyalltrueforms(avoid : Vector2i) -> void:
	var cellCoords : Vector2i
	for y in range(cell_columna):
		for x in range(cell_fila):
			cellCoords = Vector2i(x, y)
			if cells[getCellIndex(cellCoords)] == 0:
				# bomba, duh
				if not cellCoords == avoid:
					set_cell(0, cellCoords, 0, Vector2i(2, 0))
			else:
				# banderita mal puesta
				if getAtlasCoords(cellCoords) == Vector2i(1, 0):
					set_cell(0, cellCoords, 0, Vector2i(1, 3))
					
