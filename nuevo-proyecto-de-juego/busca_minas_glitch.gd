extends TileMap 
#A SOLUCIONAR (algún día) antes de empezar el tamaño del container es más grande
# -1 casilla vacia 
# 0 mina 
# 1-8 casilla numero 
 
# Columnas, filas y cantidad de minas (20% del total de casillas) 
const cell_columna := 32 
const cell_fila := 32 
const mine_count := int(cell_columna * cell_fila * 0.20) 
#Cuando partida empezada es true se activa
#CAMBIO 3-1 tiempo eliminado 
var partida_empezada := false 
#CAMBIO 3-2 contador de clicks 
var clicks := 0
# Bastante descirptivo, cantidad de clicks necesarios para que crashee.
# lo mismo que randf pero con int, se deefine una sola vez, no lo puse fijo para dar variedad
var clicks_para_crash := randi_range(3, 6)
#CAMBIO 3-3 variables para el lag y el crash
var cargando := false
var crash := false
#CAMBIO 3-4 para la """"animación"""" de cuando carga . .. ...
var puntos_carga := 0

#CAMBIO 3-1.1 Ahora el tiempo intercala entre estos
# Array con todas las probabilidades de tiempo
# \n es salto de linea
var tiempos_falsos := [
	" Tiempo: \n3 años",
	"Tiempo: \n8 meses",
	"Tiempo: \n17 segundos",
	"Tiempo: \n10 eones",
	"Tiempo: \n32 lustros",
	"Tiempo: \n20 semanas",
	"Tiempo: \nel necesario",
	"Tiempo: \n42 minutos",
	"Tiempo: \nun rato",
	"Tiempo: \nrelativo",
	"Tiempo: \ncalculando",
	"Tiempo: \n5 kilos",
]

# Muerte es gameover, cells la cantidad de casillas, cells_alrededor se usa para revelar cuando tocás una bien
var muerte := false 
var cells : Array[int] 
var cells_alrededor : Array[int] 
var offsetCoords : Vector2i 
 
# Se activa cuando empieza la escena 
func _ready() -> void: 
#CAMBIO 3-5 da seed random para el tiempo y esas cosas, por si acaso lo voy a poner en los anteriores ya que estoy 
	randomize()
	setupboard() 
	#CAMBIO 3-2.1 randomizamos la variante que hicimos antes
	clicks_para_crash = randi_range(3, 5)
	#estado
	$CanvasLayer/PanelEstado/LabelEstado.text = "Toca una casilla" 
	# CAMBIO 3-1.2 este es olo el tiempo que se muerstra al inicio, después nunca va a aparecer 
	# me acabo de dar cuenta de que cambié el sistema de cambios de todo "-" a "-" y ".". 
	# pero bueno nadie se va a dar cuenta
	$CanvasLayer/PanelTiempo/LabelTiempo.text = "Tiempo:\n 1000 "
	# CAMBIO 3-6 ahora que están las pantallas de crash y carga
	# y como están en el medio empiezan ocultas
	$CanvasLayer/PanelCarga.hide()
	$CanvasLayer/PanelCrash.hide()
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
		position.x - $CanvasLayer/PanelEstado.size.x - 40, 
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelEstado.size.y / 2 
	) 
#Pone el panel de timer a la derecha ajustaddo según tamaño
	$CanvasLayer/PanelTiempo.position = Vector2( 
		position.x + board_size_scaled.x + 40, 
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelTiempo.size.y / 2 
	) 
	# Pone la pantalla de carga en el centro centro muy centro del tablero
	$CanvasLayer/PanelCarga.position = Vector2(
		position.x + board_size_scaled.x / 2 - $CanvasLayer/PanelCarga.size.x / 2,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelCarga.size.y / 2
	)
	# Lo mismo que el otro
	$CanvasLayer/PanelCrash.position = Vector2(
		position.x + board_size_scaled.x / 2 - $CanvasLayer/PanelCrash.size.x / 2,
		position.y + board_size_scaled.y / 2 - $CanvasLayer/PanelCrash.size.y / 2
	)
# Tablero vacío 
func setupboard() -> void: 
	for y in range(cell_columna): 
		for x in range(cell_fila): 
			set_cell(0, Vector2i(x,y), 0, Vector2i(0,0)) 
			cells.append(-1) 
# Pone las minas random
func setupmines(avoid : Vector2i) -> void: 
	for i in range(mine_count): 
		cells[i] = 0 
	
	cells.shuffle() 
	
	# previene instalose y dá margen de cells vacías al rededor del inicio
	while getSurroundingCells(avoid, 5).has(0): 
		cells.shuffle() 
		
	# Ponemos las celdas de números
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
	# CAMBIO 3-7 ahora tampoco hace nada mientras está cargando o después del crash, 
	# lo cual también implica muerte pero por si acaso
	if muerte==false && cargando==false && crash==false :
			
			#Click izquierdo
		if event.is_action_pressed("ShowMeYourTrueForm"): 
			var cellAtMouse: Vector2i = local_to_map(get_local_mouse_position()) 
		# para que no se puedan clickear banderas
			if getCellIndex(cellAtMouse) == -1: 
				return 
				#CAMBIO 3-8, ahora directamente comprueba que sea casilla vacía
				# en lugar de que no sea bandera, hubiera sido más fácil si usara esto antes, pero ya fué
			if getAtlasCoords(cellAtMouse) == Vector2i(0, 0):
				
				# #CAMBIO 3-8.1, ponemos las minas directamente lo de comprobar si toca mina fué movido
				if not partida_empezada:
					setupmines(cellAtMouse)
					partida_empezada = true
					$CanvasLayer/PanelEstado/LabelEstado.text = "Jugando"
					$CanvasLayer/Timer.start()
				trueForm(cellAtMouse)
				# #CAMBIO 3-2.2,y acá se suman los clcicks como contador para el crash
				clicks += 1
				
					#CAMBIO 3-8.2, acá está la comprobación de mina, no se puede perder, crashea directo
				if cells[getCellIndex(cellAtMouse)] == 0:
					iniciar_crash()
					return
				#CAMBIO 3-2, comprueba si hay los clicks necesarios para perder
				if clicks >= clicks_para_crash:
					iniciar_crash()
					return
				
				# #CAMBIO 3-3.1, si no se detiene por ninguno de los ifs anteriores, por lo tanto hizo
				# click y no crasheó, activa el lag
				iniciar_carga()
		
					#Click derecho, este realmente no cambia
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

#Cambio 3-3.2, toda la función de lag
# Inicia la pantalla de carga entre clicks
func iniciar_carga() -> void:
	cargando = true
	# CAMBIO 3-4.1, reinicia el contador
	puntos_carga = 0
	$CanvasLayer/PanelCarga.show()
	$CanvasLayer/PanelCarga/LabelCarga.text = "Cargando."
	# CAMBIO 3-3.3 el timepo de la pantalla de carga es otro random float, porque mientras más mejor
	var tiempo_carga := randf_range(4.0, 10.0)
	# CAMBIO 3-3.4 crea el timer con el tiempo random, get_tree es importante para algo, no sé bien qué
	await get_tree().create_timer(tiempo_carga).timeout
	# CAMBIO 3-3.5 Cuando tertmina la carga, oculta el label y pasa a false
	$CanvasLayer/PanelCarga.hide()
	cargando = false


# CAMBIO 3-pi, Pantalla de carga antes del crash, es distinta
#no diferencié lag y crash antes así que me invento un cambio 3-pi, para que en vez de 3 sea 3,14
func iniciar_crash() -> void:
	# CAMBIO 3-pi.1 por si acaso comprueba si no crasheó ya
	if crash==true:
		return
	#CAMBIO 3-pi.2 lo mismo que la otra carga pero acá nunca vuelve a false y el tiempo es mayor
	cargando = true
	puntos_carga = 0
	$CanvasLayer/PanelCarga.show()
	$CanvasLayer/PanelCarga/LabelCarga.text = "Cargando."
	
	var tiempo_carga := randf_range(10.0, 15.0)
	await get_tree().create_timer(tiempo_carga).timeout
	#CAMBIO 3-pi.3 y ya crashea
	mostrar_crash()
		# ZA WAARUDO
	$CanvasLayer/Timer.stop()


# #CAMBIO 3-pi.4, muestra el label de crash
func mostrar_crash() -> void:
	cargando = false
	crash = true
	muerte = true
	
	$CanvasLayer/PanelCarga.hide()
	
	$CanvasLayer/PanelCrash.show()
	$CanvasLayer/PanelCrash/LabelCrash.text = "ERROR\nEl juego dejó de responder"
	#Como dije, no se puede perder
	$CanvasLayer/PanelEstado/LabelEstado.text = "Ganaste"


#CAMBIO 3-10 ahora el timer sirve para acer la """""""""animación"""""""""""" de cargar
# y si no está cargando, cambia el tiempo a una de las maravillosas variables, como la pantalla de carga
# cuando descargas algo, lo cual sería pantalla de descarga, no de carga, porque descarga, no carga nada
# pero bueno yo me entiendo
func _on_timer_timeout() -> void:
	if cargando==true:
		puntos_carga += 1
		
		if puntos_carga > 3:
			puntos_carga = 1
		# esto es como un switch... de hecho es lo mismo
		match puntos_carga:
			1:
				$CanvasLayer/PanelCarga/LabelCarga.text = "Cargando."
			2:
				$CanvasLayer/PanelCarga/LabelCarga.text = "Cargando.."
			3:
				$CanvasLayer/PanelCarga/LabelCarga.text = "Cargando..."
	else:
		# creo que "PICK RANDOM" es bastante explicativo en si mismo
		$CanvasLayer/PanelTiempo/LabelTiempo.text = tiempos_falsos.pick_random()

# Evento cuando click derecho
func trueForm(cellCoords : Vector2i) -> void: 
	var cellIndex : int 
	cellIndex = getCellIndex(cellCoords) 
	
	var atlasCoords : Vector2i 
	
	match cells[cellIndex]: 
		-1: atlasCoords = Vector2i(3,0) 
		0: atlasCoords = Vector2i(0,3) 
		1: atlasCoords = Vector2i(0, 1) 
		2: atlasCoords = Vector2i(1, 1) 
		3: atlasCoords = Vector2i(2, 1) 
		4: atlasCoords = Vector2i(3, 1) 
		5: atlasCoords = Vector2i(0, 2) 
		6: atlasCoords = Vector2i(1, 2) 
		7: atlasCoords = Vector2i(2, 2) 
		8: atlasCoords = Vector2i(3, 2) 
	
	set_cell(0, cellCoords, 0, atlasCoords) 
	
	if cells[cellIndex] == -1: 
		trueformalrededor(cellCoords) 


# Convierte la coordenada del click del mouse en una posición del array
func getCellIndex(cellCoords : Vector2i) -> int: 
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
			
			if getCellIndex(offsetCoords) > -1: 
				cells_alrededor.append(cells[getCellIndex(offsetCoords)]) 
			else: 
				cells_alrededor.append(-1) 
	
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


# Para mostrar las minas
func showmeyalltrueforms(avoid : Vector2i) -> void: 
	var cellCoords : Vector2i 
	
	for y in range(cell_columna): 
		for x in range(cell_fila): 
			cellCoords = Vector2i(x, y) 
			
			if cells[getCellIndex(cellCoords)] == 0: 
				if not cellCoords == avoid: 
					set_cell(0, cellCoords, 0, Vector2i(2, 0)) 
			else: 
				if getAtlasCoords(cellCoords) == Vector2i(1, 0): 
					set_cell(0, cellCoords, 0, Vector2i(1, 3)) 

#acá estaba checkwin, ya no
