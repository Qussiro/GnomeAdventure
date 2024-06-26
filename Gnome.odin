package gnome

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

width :: 1600
height :: 900
PLAYER_SPD :: 500.0
PLAYER_POWER_MAX :: 5
POWER_PER_FRAME :: 3
PLAYER_START_POS :: rl.Vector2 {250, 0}
PLAYER_SIZE :: rl.Vector2 {100, 100}
FLOOR :: rl.Rectangle {-6000, 820, 13000, 8000}
MAX_SOUND :: 10

Player :: struct {
    position: rl.Vector2,
	size: rl.Vector2,
	moveDirection: rl.Vector2,
	jumpDirection: rl.Vector2,
	speed: f32,
    canJump: bool,
	prepJump: bool,
	jumpPower: f32,
} 

resolve_collision :: proc(gnome:^Player, brick:rl.Rectangle){
	// left top corner(3 on image)
	if gnome.position.x < brick.x + brick.width/2 && gnome.position.y < brick.y+ brick.height/2 && gnome.position.x + gnome.size.x > brick.x && gnome.position.y + gnome.size.y > brick.y {
		w := gnome.position.x + gnome.size.x - brick.x
		h := gnome.position.y + gnome.size.y - brick.y
		if w < h {
			gnome.position.x += -w
			gnome.moveDirection *= {-1/2.,1/2.}
		} else { 
			gnome.position.y += -h
			gnome.moveDirection *= {1/2.,-1/2.}
		}
	}
	// right top corner(2)
	if gnome.position.x > brick.x + brick.width/2 && gnome.position.y < brick.y+ brick.height/2	&& gnome.position.x < brick.x + brick.width && gnome.position.y + gnome.size.y > brick.y{
		w := brick.x + brick.width - gnome.position.x 
		h := gnome.position.y + gnome.size.y - brick.y
		if w < h { 
			gnome.position.x += w
			gnome.moveDirection *= {-1/2.,1/2.}
		} else {
			gnome.position.y += -h
			gnome.moveDirection *= {1/2.,-1/2.}
		}
	}
	// left bottom corner(1)
	if gnome.position.x < brick.x + brick.width/2 && gnome.position.y > brick.y+ brick.height/2 && gnome.position.x + gnome.size.x > brick.x && gnome.position.y < brick.y + brick.height {
		w := gnome.position.x + gnome.size.x - brick.x
		h := brick.y + brick.height - gnome.position.y
		if w < h {
			gnome.position.x += -w
			gnome.moveDirection *= {-1/2.,1/2.}
		} else { 
			gnome.position.y += h
			gnome.moveDirection *= {1/2.,-1/2.}
		}
	}
	// right bottom corner(4)
	if gnome.position.x > brick.x + brick.width/2 && gnome.position.y > brick.y+ brick.height/2 && gnome.position.x < brick.x + brick.width && gnome.position.y < brick.y + brick.height {
		w := brick.x + brick.width - gnome.position.x 
		h := brick.y + brick.height - gnome.position.y
		if w < h {
			gnome.position.x += w
			gnome.moveDirection *= {-1/2.,1/2.}
		} else {
			gnome.position.y += h
			gnome.moveDirection *= {1/2.,-1/2.}
		}
	}
	if rl.FloatEquals(gnome.position.y + gnome.size.y, brick.y) do gnome.canJump = true
}

load_textures :: proc() {
}

Look_Dir :: enum {left, right}

main :: proc() {
	gnome := Player{
		PLAYER_START_POS, 
		PLAYER_SIZE, 
		{0,1},
		{0,0}, 
		PLAYER_SPD, 
		false,
		false,
		0.5,
	}
	brick := rl.Rectangle{
		500,
		500,
		400,
		200,
	}
    rl.InitWindow(width, height, "Gnome")
    rl.InitAudioDevice()
    rl.SetTargetFPS(60)

	// Gnome texture	
    gnome_img := rl.LoadImage("./res/gnome2.png")
    defer rl.UnloadImage(gnome_img)

    rl.ImageResizeNN(&gnome_img, cast(i32)PLAYER_SIZE.x, cast(i32)PLAYER_SIZE.y)
	gnome_tex_right := rl.LoadTextureFromImage(gnome_img)

	rl.ImageFlipHorizontal(&gnome_img)
	gnome_tex_left := rl.LoadTextureFromImage(gnome_img)

	// Gnome sounds
	gnome_rot_sound : [MAX_SOUND] rl.Sound
	gnome_rot_sound[0] = rl.LoadSound("./res/the-rock-meme-sound-effect.mp3")

    for i := 1; i < MAX_SOUND; i+=1
    {
        gnome_rot_sound[i] = rl.LoadSoundAlias(gnome_rot_sound[0]);
    }
    currentSound := 0;
	
	look := Look_Dir.right
	
	for !rl.WindowShouldClose() {
		deltaTime := rl.GetFrameTime()
		rl.BeginDrawing()
		
		rl.ClearBackground(rl.RAYWHITE)
		rl.DrawRectangleRec(FLOOR, rl.DARKGRAY)
		rl.DrawText("Congrats! You created your first window!", 190, 200, 50, rl.LIGHTGRAY)
		  
		if rl.IsKeyDown(rl.KeyboardKey.LEFT) && gnome.canJump && !gnome.prepJump {
			gnome.moveDirection = {-1,0}
			if look == .right {
				rl.PlaySound(gnome_rot_sound[currentSound])
				currentSound = (currentSound + 1) % len(gnome_rot_sound)
			}
			look = .left
		}
		
   		if rl.IsKeyDown(rl.KeyboardKey.RIGHT) && gnome.canJump && !gnome.prepJump{
			gnome.moveDirection = {1,0}
			if look == .left {
				rl.PlaySound(gnome_rot_sound[currentSound])
				currentSound = (currentSound + 1) % len(gnome_rot_sound)
			}
			look = .right
		}    
   		if gnome.canJump && !rl.IsKeyDown(rl.KeyboardKey.LEFT) && !rl.IsKeyDown(rl.KeyboardKey.RIGHT) {gnome.moveDirection = {0,0}}

		if rl.IsKeyDown(rl.KeyboardKey.UP) && gnome.canJump {
			gnome.moveDirection = {0,0}
			gnome.jumpDirection = {0,-1}
			gnome.prepJump = true
			gnome.jumpPower += deltaTime*POWER_PER_FRAME
			if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
				gnome.jumpDirection = {-0.58,-0.8}
				if look == .right {
					rl.PlaySound(gnome_rot_sound[currentSound])
					currentSound = (currentSound + 1) % len(gnome_rot_sound)
				}
				look = .left
			}
			if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
				gnome.jumpDirection = {0.58,-0.8}
				if look == .left {
					rl.PlaySound(gnome_rot_sound[currentSound])
					currentSound = (currentSound + 1) % len(gnome_rot_sound)
				}
				look = .right
			}
			if gnome.jumpPower > PLAYER_POWER_MAX {
				gnome.jumpPower = PLAYER_POWER_MAX
			}

			
			rl.DrawRectangleV(
				{gnome.position.x-50, gnome.position.y-(gnome.jumpPower-2)/(PLAYER_POWER_MAX-2)*100},
				{20, (gnome.jumpPower-2)/(PLAYER_POWER_MAX-2)*100},
				rl.RED
			)	
		}
		if !rl.IsKeyDown(rl.KeyboardKey.UP) && gnome.prepJump{
			fmt.println(gnome.jumpPower)
			gnome.moveDirection = gnome.jumpDirection*gnome.jumpPower
			gnome.jumpPower = 2
			gnome.prepJump = false
			gnome.canJump = false
		}
		
		gnome.moveDirection += {0,1}*deltaTime*9.8
		gnome.position += gnome.speed*gnome.moveDirection*deltaTime    
		
		gnome.canJump = false
		resolve_collision(&gnome, brick)
		resolve_collision(&gnome, FLOOR)
		
		if gnome.position.y >= 820-gnome.size.y {
			gnome.position.y = 820-gnome.size.y
			gnome.canJump = true
		}
		rl.DrawFPS(20,20)
		rl.DrawText("Gnome:", 20, 80, 40, rl.BLACK)	
		rl.DrawText(fmt.caprintf("%v",gnome.position.x), 20, 140, 40, rl.BLACK)	
		rl.DrawText(fmt.caprintf("%v",gnome.position.y), 20, 200, 40, rl.BLACK)	
		
		brick.y = cast(f32) -math.abs(math.sin(rl.GetTime()))*200+650
		rl.DrawRectangleRec(brick, rl.BLACK)
		
		if !gnome.prepJump { 
			if look == .right do rl.DrawTextureV(gnome_tex_right, gnome.position, rl.WHITE)
			else do rl.DrawTextureV(gnome_tex_left, gnome.position, rl.WHITE)
		} else {
			stretch := (gnome.jumpPower-2)/(PLAYER_POWER_MAX-2)
			if look == .right {
				rl.DrawTexturePro(gnome_tex_right, {0, 0, 100, 100}, {gnome.position.x-(stretch/2)*50, gnome.position.y+(stretch/2)*100, (1+stretch/2)*100, (1-stretch/2)*100}, {0,0}, 0, rl.WHITE)
			} else {
				rl.DrawTexturePro(gnome_tex_left, {0, 0, 100, 100}, {gnome.position.x-(stretch/2)*50, gnome.position.y+(stretch/2)*100, (1+stretch/2)*100, (1-stretch/2)*100}, {0,0}, 0, rl.WHITE)
			}
		}

		rl.EndDrawing()
	}

	rl.CloseWindow()
}
