extends TileMap
# -1 casilla vacia
# 0 mina
# 1-8 casilla numero

#Columnas, filas y cantidad de minas (20% del total de casillas)
const cell_columna := 16
const cell_fila := 16
const mine_count := int(cell_columna * cell_fila * 0.20)
# CAMBIO 5-1, el primero es la posibilidad de que una pista no sea pista
# el segundo es la probabilidad de que haya una mina regalada
# y el tercero es el tiempo para que ese regalo despawnee. a cada click se randomiza
# para cambiarlo ir a 5-1.1
const probabilidad_pregunta := 0.20
const probabilidad_pista := 1.0
var tiempo_pista = 1

#Tiempo para jugar, cuando partida empezada es true se activa 
var tiempo_restante := 1000
var partida_empezada := false
var panel_size := Vector2(100, 40)
#Muerte es gameover, cells la cantidad de casillas, cells_alrededor se usa para revelar cuando tocás una bien
var muerte := false
var cells : Array[int]
var cells_alrededor : Array[int]
var offsetCoords : Vector2i



# Se activa cuando empieza la escena
func _ready() -> void:
	randomize()
	setupboard()
	#estado
	$CanvasLayer/PanelEstado/LabelEstado.text = "Toca una casilla"
	#timer
	$CanvasLayer/PanelTiempo/LabelTiempo.text = "Tiempo: " + str(tiempo_restante)
	#ajusta el tamaño de la pantalla al necesario
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(cell_fila, cell_columna) * 16
	# minf devbuelve el menor entre 2 floats, no se muy bien para qué es pero si funciona no lo arreglo
	var scale_factor: float = minf(
		viewport_size.x / board_size.x,
		viewport_size.y / board_size.y
	)
	#IMPORTANTE PONER AUTOWRAP MODE EN "WORD (SMART)" ASÍ SE AJUSTAN BIEN LAS PALABRAS AL TAMAÑO QUE QUIERA
	scale = Vector2.ONE * scale_factor
	position = (viewport_size - board_size * scale_factor) / 2
	
	var board_size_scaled := board_size * scale_factor
#Pone el panel de estado a la izquierda ajustaddo según tamaño
	$CanvasLayer/PanelEstado.position = Vector2(
		position.x - $CanvasLayer/PanelEstado.size.x - 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2
	)
#Pone el panel de timer a la derecha ajustaddo según tamaño
	$CanvasLayer/PanelTiempo.position = Vector2(
		position.x + board_size_scaled.x + 60,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelTiempo.size.y / 2
	)
# Tablero vacío
func setupboard() -> void:
	for y in range(cell_columna):
		for x in range(cell_fila):
			set_cell(0, Vector2i(x,y), 0, Vector2i(0,0))
			cells.append(-1)
#Pone las minas random
func setupmines(avoid : Vector2i) -> void:
	for i in range(mine_count):
		cells[i] = 0
	
	cells.shuffle()
	
	# previene instalose y dá margen de cells vacías al rededor del inicio
	while getSurroundingCells(avoid, 5).has(0):
		cells.shuffle()
		
		#ponemos las celss de numeros
	for y in range(cell_columna):
		for x in range(cell_fila):
			
			if not cells[getCellIndex(Vector2i(x, y))] == 0:
				var mineCount := 0
				for i in getSurroundingCells(Vector2i(x, y), 3):
					if i == 0:
						mineCount += 1
				if mineCount > 0:
					cells[getCellIndex(Vector2i(x, y))] = mineCount


# Detectar Clicks en las cells
func _input(event: InputEvent) -> void:
	#No hace nada si hay gameover
	if muerte==false:
		#5-1.1 para rerrollear el tiempo de desaparición
		tiempo_pista = randf_range(0.1,3.0)
			#Click izquierdo
		if event.is_action_pressed("ShowMeYourTrueForm"):
			var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
		# para que no se puedan clickear banderas
			if getCellIndex(cellAtMouse) == -1:
				return
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				if cells.has(0):
					trueForm(cellAtMouse)
					checkWin()
					#CAMBIO 5-2, no hay nada que explicar, lo hice mil veces. La función está al final
					if randf() < probabilidad_pista:
						pista_mina()
			# si el clickea una mina (0), shinu
					if cells[getCellIndex(cellAtMouse)] == 0:
						muerte = true
						$CanvasLayer/Timer.stop()
						$CanvasLayer/PanelEstado/LabelEstado.text = "Kaboom"
						showmeyalltrueforms(cellAtMouse)
						
						#Sino, siga siga
				else:
					setupmines(cellAtMouse)
					trueForm(cellAtMouse)
					pista_mina()
					partida_empezada = true
					$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
					$CanvasLayer/Timer.start()
					checkWin()
					#Click derecho
		if event.is_action_pressed("flag"):
			var cellAtMouse : Vector2i = local_to_map(get_local_mouse_position())
			# Si es casilla sin ver
			if getCellIndex(cellAtMouse) == -1:
				return
				#5-2.7, ahora también comprueba si es !
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0) or getAtlasCoords(cellAtMouse) == Vector2i(3, 3):
				# Hace casilla con flag
				set_cell(0, cellAtMouse, 0, Vector2i(1, 0))
				# Si es casilla con flag
			elif getAtlasCoords(cellAtMouse) == Vector2i(1, 0):
				# Hace casilla sin ver
				set_cell(0, cellAtMouse, 0, Vector2i(0, 0))
				
# Evento cuando click derecho 
# CAMBIO 5-2, ahora hay un un if con el maravilloso randf para determinar si la pista no está 
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
	
# 5-2.1 comprueba si es número
	if cells[cellIndex] >= 1 && cells[cellIndex] <= 8:
# 2,3 es el ?
		if randf() < probabilidad_pregunta:
			atlasCoords = Vector2i(2, 3)
	
	set_cell(0, cellCoords, 0, atlasCoords)
	
	# Si está sin revelar, revela este y su alrededor
	if cells[cellIndex] == -1:
		trueformalrededor(cellCoords)


# convierte la coordenada del click del mouse en una posición del array de las casillas
func getCellIndex(cellCoords : Vector2i) -> int:
	# Comprueba si el click está dentro de los limites del tablero
	if cellCoords.x < cell_fila and cellCoords.y < cell_columna:
		if cellCoords.x >= 0 and cellCoords.y >= 0:
			return cellCoords.y * cell_fila + cellCoords.x
		else:
			return -1
	else:
		return -1
		

# Don't set size too high or it will lag/crash the game. OK
func getSurroundingCells(cellCoords : Vector2i, size : int) -> Array[int]:
	cells_alrededor = []
	for y in range(-1, size-1):
		for x in range(-1, size-1):
			offsetCoords = cellCoords + Vector2i(x, y)
			# Si las cells de alrededor no están vacás
			if getCellIndex(offsetCoords) > -1:
				cells_alrededor.append(cells[getCellIndex(offsetCoords)])
			else:
				cells_alrededor.append(-1)
				# Devuelve la información de que hay alrededor
	return cells_alrededor

# Revela las casillas vacías
func trueformalrededor(cellCoords : Vector2i) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			offsetCoords = cellCoords-Vector2i(x , y)
			if getCellIndex(offsetCoords) > -1:
					if getAtlasCoords(offsetCoords) == Vector2i(0,0) or getAtlasCoords(offsetCoords) == Vector2i(1,0):
						trueForm(offsetCoords)

func getAtlasCoords(cellCoords : Vector2i) -> Vector2i:
	return get_cell_atlas_coords(0, cellCoords)
	
	#Para la derrota
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
					
#función para timer
func _on_timer_timeout() -> void:
	tiempo_restante -= 1
	$CanvasLayer/PanelTiempo/LabelTiempo.text = str(tiempo_restante)
	
	if tiempo_restante <= 0:
		muerte = true
		$CanvasLayer/Timer.stop()
		$CanvasLayer/PanelEstado/LabelEstado.text = "Se acabó el tiempo"
		showmeyalltrueforms(Vector2i(-1, -1))
		
		
# Función para ganar
func checkWin() -> void:
	var unrevealed := 0
	
	for y in range(cell_columna):
		for x in range(cell_fila):
			var cellCoords := Vector2i(x, y)
			var atlasCoords := getAtlasCoords(cellCoords)
			
			if atlasCoords == Vector2i(0, 0) or atlasCoords == Vector2i(1, 0):
				unrevealed += 1
	
	if unrevealed == mine_count:
		muerte = true
		$CanvasLayer/Timer.stop()
		$CanvasLayer/PanelEstado/LabelEstado.text = "Ganaste"
#5-2.1 la función
func pista_mina() -> void:
	# 5-2.2 hace lo mismo que las otras funciones quer buscan minas
	var minas := []
	
	for y in range(cell_columna):
		for x in range(cell_fila):
			var cellCoords := Vector2i(x, y)
			
			if cells[getCellIndex(cellCoords)] == 0:
				if getAtlasCoords(cellCoords) == Vector2i(0, 0):
					minas.append(cellCoords)
	
	# 5-2.3 si no hay minas sin revelar no hace nada. 
	# Por si acaso, porque no debería ser posible, porque ya hubieras ganado
	if minas.is_empty():
		return
	
	# 5-2.4 agarra la posición de una mina random dentro del array del 5-2.2
	var mina = minas.pick_random()
	# 3,3 es el !
	set_cell(0, mina, 0, Vector2i(3, 3))
# 5-2.5 el await awaitea el tiempo de la variable antes de desaparecer el !
	await get_tree().create_timer(tiempo_pista).timeout
	
	# 5-6 quita el ! si sigue estando ahí, sino te podría sacar una bandera
	if getAtlasCoords(mina) == Vector2i(3, 3):
		set_cell(0, mina, 0, Vector2i(0, 0))
