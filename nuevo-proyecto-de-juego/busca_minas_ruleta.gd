extends TileMap
# -1 casilla vacia
# 0 mina
# 1-8 casilla numero

#Columnas, filas y cantidad de minas (20% del total de casillas)
const cell_columna := 16
const cell_fila := 16
const mine_count := int(cell_columna * cell_fila * 0.20)

# CAMBIO 2-1, agregamos las posibilidades de que pase lo que no tiene que pasar, lo positivo y lo negativo es 
# inversamente equivalente
const probabilidad_inicial := 0.05
const aumento_probabilidad := 0.05
# las posibilidades de no explotar cuando deberías y viceversa son opuestas, por ejemplo si una es 60/40, 
# la otra 40/60, por lo tanto al final una va a ser 100 y la otra 0, siendo muerte asegurada
var probabilidad_explotar := probabilidad_inicial
var probabilidad_desactivar:= 1-probabilidad_explotar
# CAMBIO 2-2 por como terminó siendo el códiogo debería llamarse "no explota" pero da igual
# esta la voy a estar declarando en cada click con un random float que me encantó
var explota : bool

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
	# ya que se que existe lo pongo por las dudas, originalmente cambio 3.5
	randomize()
	setupboard()
	#estado
	$CanvasLayer/PanelEstado/LabelEstado.text = "Toca una casilla"
	#timer
	$CanvasLayer/PanelTiempo/LabelTiempo.text = "Tiempo: " + str(tiempo_restante)
	#probabilidad
	$CanvasLayer/PanelProbabilidad/LabelProbabilidad.text = "Probabilidad: " + "A favor: " + str(probabilidad_desactivar*100) + " En contra: " + str(probabilidad_explotar*100) 
	#ajusta el tamaño de la pantalla al necesario
	var viewport_size := get_viewport_rect().size
	var board_size := Vector2(cell_fila, cell_columna) * 16
	# minf devbuelve el menor entre 2 floats, no se muy bien para qué es pero si funciona no lo arreglo
	var scale_factor: float = minf(
		viewport_size.x / board_size.x,
		viewport_size.y / board_size.y
	)
	
	scale = Vector2.ONE * scale_factor
	position = (viewport_size - board_size * scale_factor) / 2
	
	var board_size_scaled := board_size * scale_factor
	#PARA MI YO DEL FUTURO: por favor hacer una forma más comodo de m,over los labels porque me voy a pegar un tiro
	# O sino acostumbrate lo suficiente como para que no lo quiera cambiar más
	#IMPORTANTE PONER AUTOWRAP MODE EN "WORD (SMART)" ASÍ SE AJUSTAN BIEN LAS PALABRAS AL TAMAÑO QUE QUIERA
#Pone el panel de estado a la izquierda ajustaddo según tamaño
	$CanvasLayer/PanelEstado.position = Vector2(
		position.x - $CanvasLayer/PanelEstado.size.x - 30,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2
	)

#Pone el panel de timer a la derecha ajustaddo según tamaño
	$CanvasLayer/PanelTiempo.position = Vector2(
		position.x + board_size_scaled.x + 30,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelTiempo.size.y / 0.3
	)
#al de probabilidad lo pongo en relación al de tiempo, un poco más abajo
	
	$CanvasLayer/PanelProbabilidad.position = Vector2(
	$CanvasLayer/PanelTiempo.position.x,
	$CanvasLayer/PanelTiempo.position.y + $CanvasLayer/PanelTiempo.size.y *4
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
			
			#Click izquierdo
		if event.is_action_pressed("ShowMeYourTrueForm"):
			var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
			if getCellIndex(cellAtMouse) == -1:
				return
			# para que no se puedan clickear banderas
			if getAtlasCoords(cellAtMouse) != Vector2i(1, 0):
				if cells.has(0):
					# CAMBIO 2-2 Acá se calcula la posibilidad, la cual es, bueno, la variablwe de posibilidad
					explota = randf() > probabilidad_explotar
					if explota==false:
						muerte = true
						$CanvasLayer/Timer.stop()
						# Este mensaje diferencia cuando morís por ruleta
						$CanvasLayer/PanelEstado/LabelEstado.text = "Kaboom, mala suerte"
						showmeyalltrueforms(cellAtMouse)
					
					#CAMBIO 2-3, lo mismo que en el 1-2, comprobamos si es click a la casilla correcta
					var casilla_sin_revelar := getAtlasCoords(cellAtMouse) == Vector2i(0, 0)
					if casilla_sin_revelar:
						probabilidad_explotar += aumento_probabilidad 
						probabilidad_desactivar= 1-probabilidad_explotar
						$CanvasLayer/PanelProbabilidad/LabelProbabilidad.text = "Probabilidad: " + "A favor: " + str(probabilidad_desactivar*100) + " En contra: " + str(probabilidad_explotar*100) 

					trueForm(cellAtMouse)
					checkWin()
			
			# si el clickea una mina (0), shinu
					if cells[getCellIndex(cellAtMouse)] == 0:
						# CAMBIO 2-4 lo mismo que el 2-2 pero al revés
						# lo del && muerte==false es porque sino no ponía el mensaje de derrota 
						# si la ultima casilla tocada te había salvado la suerte
						explota = randf() > probabilidad_desactivar
						if explota==false && muerte==false:
							$CanvasLayer/PanelEstado/LabelEstado.text = "Te salvaste, que buena suerte"
							
						if explota==true:
							muerte = true
							$CanvasLayer/Timer.stop()
							$CanvasLayer/PanelEstado/LabelEstado.text = "Kaboom"
							showmeyalltrueforms(cellAtMouse)
							return #funciona sin return pero por si acaso
						#Sino, siga siga
				else:
					setupmines(cellAtMouse)
					trueForm(cellAtMouse)
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
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				# Hace casilla con flag
				set_cell(0, cellAtMouse, 0, Vector2i(1, 0))
				# Si es casilla con flag
			elif getAtlasCoords(cellAtMouse) == Vector2i(1, 0):
				# Hace casilla sin ver
				set_cell(0, cellAtMouse, 0, Vector2i(0, 0))
				
# Evento cuando click derecho 
func trueForm(cellCoords : Vector2i) -> void:
	# Codigo de las casillas en la textura
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
		$CanvasLayer/PanelProbabilidad/LabelProbabilidad.text = "Probabilidad: " + "A favor: " + str(1) + " En contra: " + str(99) 
		$CanvasLayer/PanelEstado/LabelEstado.text = "Casi, pero perdiste"
		var cellAtMouse: Vector2i =local_to_map(get_local_mouse_position())
		showmeyalltrueforms(cellAtMouse)
