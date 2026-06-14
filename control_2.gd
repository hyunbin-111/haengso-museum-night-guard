extends Control

@onready var pages = $pages
@onready var label = $Label
@onready var dialogueUI = $"../DialogueUI"
@onready var label2 = $RichTextLabel
@onready var manual_toggle_sound: AudioStreamPlayer = $ManualToggleSound
@onready var page_flip_sound: AudioStreamPlayer = $PageFlipSound

var current_page = 0
var max_page = 3
var is_open = true

var texts = [
	"         행소박물관 야간경비원 근무수칙  
	
	0. 근무수칙을 따르지 않은 모든 결과의
	책임은 본인에게 있습니다.
	
	1. 근무시간은 22시부터 06시까지입니다.
	순찰 시간이 되면 전시실의 길을 따라 한
	바퀴씩 순찰해주십시오.
	
	2. 행소박물관에서는 몇몇 유물들이 살아
	움직입니다. 그들을 잘 다루며 근무하시길
	바랍니다.
	
	3. 다음 페이지부터는 유물들을 다루는 
	방법이 적혀있습니다. 꼭 읽으십시오.",
	
	"             대명캠퍼스 본관 종탑의 초기 종
	                           [img width=120 height=120]res://assets/Exhibits/bb15704f-0400-41fc-b51e-227f370c4e06.png[/img]
	    로비에 전시되어있는 대명캠퍼스 본관 
	    종탑의 초기 종 전시물입니다.
	
	    이 종은 제한시간 안에 [E]를 눌러 
	    진정시켜줘야 합니다. 하지만 너무 
	    자주 누르지 마십시오. 누를 때마다
	    제한시간이 줄어듭니다.
	
	    종소리를 3번 들으면 당신은 죽습니다. 
	    종을 진정시키는 것을 절대 잊어버리지 
		마십시오.",
	"                            가야의 기마병
	                            [img width=120 height=120]res://assets/Exhibits/horseman/splitanimage-r1-c1.png[/img]
	    2전시실에 전시되어있는 가야의 기마병
	    전시물입니다.
	
	    자주 출몰하지는 않지만 마주친다면
	    최대한 멀리 도망다니십시오. 그들은
	    벽따위 신경쓰지 않습니다.
	    
	    잡히면 죽@습니다.
	",
	"                                 [조작법]
	                         WASD - 이동
	                         E - 상호작용
	                         F - 손전등
	                         우클릭 - 근무수칙
					
	       우클릭을 눌러 근무수칙을 닫고 경비를
		   시작해주십시오.
			
		   근무 중에도 언제든지 우클릭을 눌러
		   근무수칙을 볼 수 있습니다.
	"
]
var rich_texts = [
	"                             후투티
	                       [img width=120 height=120]res://assets/Exhibits/bird/splitanimage-r1-c3.png[/img]
	행소기념실에 전시되어있는 계명대의
	교조, 후투티입니다.
	
	장난기가 많아 밤이 되면 항상 돌아
	다닙니다. 
	
	근무가 끝나기 전까지 20마리를 
	잡으십시오. 
	
	가까이 왔을 때 [E]를 눌러 잡을 수
	있습니다.
	",
	"                            주먹도끼
	                       [img widh=120 height=120]res://assets/Exhibits/5f8d8284-fa1c-4957-b479-cf1e3d4f970a.png[/img]
	1전시실에 전시되어있는 주먹도끼
	전시물입니다.
	
	탈출 시 빨리 없애지 않으면 수가
	늘어나니 바로 없애는 것을 추천합
	니다.
	
	손전등으로 5초 동안 비추면 사라
	집니다. 닿으면 목숨을 잃을 수 있
	으니 주의하십시오.
	
	근무가 끝났을 때 하나라도 남아있으
	면 안됩니다.
	",
	"
	                          순찰 근무
          [img widh=340 height=340]res://assets/Exhibits/스크린샷 2026-06-06 191928.png[/img]
	  특정 시간마다 1전시실과 2전시실에 빛
	  나는 길을 따라 전시실을 한 바퀴씩 
	  순찰해주십시오. 
	  총 5번의 근무 중 4번을 성공해야 합니
	  다.
		
	"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()



func _on_right_button_pressed() -> void:
		if current_page < max_page:
			play_page_flip_sound()
			label.visible = true
			pages.play("pages_right")


func _on_left_button_pressed() -> void:
	if current_page > 0:
		play_page_flip_sound()
		label.visible = false
		pages.play("pages_left")


func _on_pages_animation_finished() -> void:
	if pages.animation == "pages_right":
		current_page += 1
	elif pages.animation == "pages_left":
		current_page -= 1
	label.visible = true
	update_ui()

func update_ui():
	update_normal_text()
	update_rich_text()

	$left_Button.disabled = (current_page == 0)
	$right_Button.disabled = (current_page == max_page)
	
	
func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_book_toggle"):
		return

	var main := get_tree().current_scene

	if main == null:
		return

	# 게임오버/클리어 상태면 무시
	if "game_ended" in main and main.game_ended:
		return

	# 아직 게임 시작 전인데 Manual이 안 보이면 무시
	# 즉, DialogueUI 중 우클릭은 여기서 막힘
	if "game_started" in main and not main.game_started and not visible:
		return

	toggle_book()

func toggle_book() -> void:
	is_open = !is_open
	visible = is_open
	
	play_manual_toggle_sound(is_open)

	# 책을 닫았을 때만 Main에게 알림
	if not is_open:
		var main := get_tree().current_scene

		if main != null and main.has_method("on_manual_closed"):
			main.on_manual_closed()

func play_manual_toggle_sound(opening: bool) -> void:
	if manual_toggle_sound == null:
		return

	manual_toggle_sound.stop()

	if opening:
		manual_toggle_sound.pitch_scale = 1.05
	else:
		manual_toggle_sound.pitch_scale = 0.9

	manual_toggle_sound.play()
	
func update_normal_text() -> void:
	label.text = texts[current_page]

func start_game_logic() -> void:
	var manager := get_tree().get_first_node_in_group("ExhibitManager")

	if manager != null and manager.has_method("start_exhibit_logic"):
		manager.start_exhibit_logic()
		
func update_rich_text() -> void:
	label2.clear()

	if current_page < rich_texts.size():
		label2.append_text(rich_texts[current_page])
	else:
		label2.append_text("")
		
func play_page_flip_sound() -> void:
	if page_flip_sound == null:
		return

	page_flip_sound.stop()
	page_flip_sound.pitch_scale = randf_range(0.95, 1.05)
	page_flip_sound.play()
