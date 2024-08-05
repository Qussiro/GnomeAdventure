package gnome

import "core:fmt"
import "core:strings"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1600
SCREEN_HEIGHT :: 900
PLAYER_SPD :: 500.0
PLAYER_POWER_MAX :: 5
POWER_PER_FRAME :: 3
PLAYER_START_POS :: rl.Vector2 {250, 0}
PLAYER_SIZE :: rl.Vector2 {100, 100}
MAX_SOUND :: 10
BRICK_COUNT :: 4

Player :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    moveDirection: rl.Vector2,
    jumpDirection: rl.Vector2,
    canJump: int,
    prepJump: bool,
    jumpPower: f32,
    swingDir: int,

}

Brick :: struct {
    position: rl.Vector2,
    size: rl.Vector2,
    color: rl.Color
}

State :: struct {
    gnome: Player,
    bricks: [BRICK_COUNT]Brick,
    bricksPos: [BRICK_COUNT]rl.Vector2,
    gnome_tex: rl.Texture,
    gnome_rot_sound: [MAX_SOUND] rl.Sound,
    currentSound: int,
    look: Look_Dir,
    time: f32,
    hookPos: rl.Vector2,
    hooked: bool,
    needPoint: rl.Vector2,
    deltaTime: f32,
    hookLength: f32,
    hookedBrick: int,
    hookAngle: f32,
    hookAngleVelocity: f32,
    cam: rl.Camera2D
}



state := State {
    gnome = {
        PLAYER_START_POS, 
        PLAYER_SIZE, 
        {0,1},
        {0,0},  
        -1,
        false,
        0.5,
        -1,
    },
    bricks = {
        {
            {-6000, 820},
            {13000, 8000},
            rl.GRAY
        },
        {
            {130, 500},
            {400, 200},
            rl.DARKGREEN       
        },
        {
            {900, 500},
            {400, 200},
            rl.DARKGREEN       
        },
        {
            {500, 300},
            {400, 200},   
            rl.DARKGREEN
        },
    },
    
    
}
    
resolve_collision :: proc(gnome:^Player, brick:Brick) -> Collision_Side {
    // left top corner(3 on image)
    if gnome.position.x <= brick.position.x + brick.size.x/2 && gnome.position.y <= brick.position.y + brick.size.y/2 && gnome.position.x + gnome.size.x >= brick.position.x && gnome.position.y + gnome.size.y >= brick.position.y {
        w := gnome.position.x + gnome.size.x - brick.position.x
        h := gnome.position.y + gnome.size.y - brick.position.y
        if w <= h {
            gnome.position.x += -w
            gnome.moveDirection *= {-1/2.,1/2.}
            return .other
        } else { 
            gnome.position.y += -h
            gnome.moveDirection *= {1/2.,-1/2.}
            return .top
        }
    }
    // right top corner(2)
    if gnome.position.x >= brick.position.x + brick.size.x/2 && gnome.position.y <= brick.position.y + brick.size.y/2 && gnome.position.x <= brick.position.x + brick.size.x && gnome.position.y + gnome.size.y >= brick.position.y{
        w := brick.position.x + brick.size.x - gnome.position.x 
        h := gnome.position.y + gnome.size.y - brick.position.y
        if w <= h { 
            gnome.position.x += w
            gnome.moveDirection *= {-1/2.,1/2.}
            return .other
        } else {
            gnome.position.y += -h
            gnome.moveDirection *= {1/2.,-1/2.}
            return .top
        }
    }
    // left bottom corner(1)
    if gnome.position.x <= brick.position.x + brick.size.x/2 && gnome.position.y >= brick.position.y + brick.size.y/2 && gnome.position.x + gnome.size.x >= brick.position.x && gnome.position.y <= brick.position.y + brick.size.y {
        w := gnome.position.x + gnome.size.x - brick.position.x
        h := brick.position.y + brick.size.y - gnome.position.y
        if w <= h {
            gnome.position.x += -w
            gnome.moveDirection *= {-1/2.,1/2.}
        } else { 
            gnome.position.y += h
            gnome.moveDirection *= {1/2.,-1/2.}
        }
        return .other
    }
    // right bottom corner(4)
    if gnome.position.x >= brick.position.x + brick.size.x/2 && gnome.position.y >= brick.position.y + brick.size.y/2 && gnome.position.x <= brick.position.x + brick.size.x && gnome.position.y <= brick.position.y + brick.size.y {
        w := brick.position.x + brick.size.x - gnome.position.x 
        h := brick.position.y + brick.size.y - gnome.position.y
        if w <= h {
            gnome.position.x += w
            gnome.moveDirection *= {-1/2.,1/2.}
        } else {
            gnome.position.y += h
            gnome.moveDirection *= {1/2.,-1/2.}
        }
        return .other
    }
    return .none
}

draw_hook :: proc(hookPos:rl.Vector2, gnome:^Player, brick:Brick) -> (rl.Vector2, bool) {
    needPoint : rl.Vector2

    a, b := find_line(hookPos, gnome.position + gnome.size/2)

    // Bottom
    x := (brick.position.y + brick.size.y - b) / a 
    needPoint = {x, brick.position.y + brick.size.y} - {brick.position.x, brick.position.y}
    if x >= brick.position.x && x <= brick.position.x + brick.size.x && gnome.position.y > brick.position.y + brick.size.y do return needPoint, true

    // Left wall 

    needPoint = {brick.position.x, a * brick.position.x + b} - {brick.position.x, brick.position.y}
    if a * brick.position.x + b >= brick.position.y && a * brick.position.x + b <= brick.position.y + brick.size.y && gnome.position.x + gnome.size.x <= brick.position.x && state.look == .right do return needPoint, true

    // Right wall 

    needPoint = {brick.position.x + brick.size.x, a * (brick.position.x + brick.size.x) + b} - {brick.position.x, brick.position.y}
    if a * (brick.position.x + brick.size.x) + b >= brick.position.y && a * (brick.position.x + brick.size.x) + b <= brick.position.y + brick.size.y && gnome.position.x + gnome.size.x >= brick.position.x + brick.size.x && state.look == .left do return needPoint, true

    return needPoint, false
}

load_texture :: proc() {    
    gnome_img := rl.LoadImage("./res/gnome2.png")
    defer rl.UnloadImage(gnome_img)

    rl.ImageResizeNN(&gnome_img, cast(i32)PLAYER_SIZE.x, cast(i32)PLAYER_SIZE.y)
    state.gnome_tex = rl.LoadTextureFromImage(gnome_img)

    rl.SetTextureWrap(state.gnome_tex, rl.TextureWrap.MIRROR_REPEAT)
    // rl.ImageFlipHorizontal(&gnome_img)
    // gnome_tex_left := rl.LoadTextureFromImage(gnome_img)
}

load_sound :: proc() {
    state.gnome_rot_sound[0] = rl.LoadSound("./res/the-rock-meme-sound-effect.mp3")

    for i := 1; i < MAX_SOUND; i+=1
    {
        state.gnome_rot_sound[i] = rl.LoadSoundAlias(state.gnome_rot_sound[0])
    }
}

user_input :: proc() {
    using state
    
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) && gnome.canJump >= 0 && !gnome.prepJump {
        gnome.moveDirection = {-1,0}
        if look == .right {
            rl.PlaySound(gnome_rot_sound[currentSound])
            currentSound = (currentSound + 1) % len(gnome_rot_sound)
        }
        look = .left
    }

       if rl.IsKeyDown(rl.KeyboardKey.RIGHT) && gnome.canJump >= 0 && !gnome.prepJump{
        gnome.moveDirection = {1,0}
        if look == .left {
            rl.PlaySound(gnome_rot_sound[currentSound])
            currentSound = (currentSound + 1) % len(gnome_rot_sound)
        }
        look = .right
    }    
    if gnome.canJump >= 0 && !rl.IsKeyDown(rl.KeyboardKey.LEFT) && !rl.IsKeyDown(rl.KeyboardKey.RIGHT) {gnome.moveDirection = {0,0}}

    if rl.IsKeyDown(rl.KeyboardKey.UP) && gnome.canJump >= 0 {
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
    if !rl.IsKeyDown(rl.KeyboardKey.UP) && gnome.prepJump && gnome.canJump >= 0 {
        fmt.println(gnome.jumpPower)
        gnome.moveDirection = gnome.jumpDirection*gnome.jumpPower
        gnome.jumpPower = 2
        gnome.prepJump = false
        gnome.canJump = -1
    }
    if rl.IsKeyReleased(rl.KeyboardKey.Z) && hooked == true 
    {
        hooked = false
        gnome.canJump = -1

        vect := actual_gnome_position() - actual_needed_point(hookedBrick)
        gnome.moveDirection = 50 * rl.Vector2Normalize(rl.Vector2Rotate(vect, math.PI/2)) * hookAngleVelocity
    }
    if rl.IsKeyDown(rl.KeyboardKey.LEFT) && gnome.canJump == -2 && look == .right {
        hookAngleVelocity += 0.055
        look = .left
    }
    if rl.IsKeyDown(rl.KeyboardKey.RIGHT) && gnome.canJump == -2 && look == .left {
        hookAngleVelocity -= 0.055
        look = .right
    }
    

    if rl.IsKeyDown(rl.KeyboardKey.X) && hooked == false {
        time += deltaTime * 2
        angle := cast(f32) -(1 + math.sin(time)) * math.PI / 4

        if look == .right {
            hookPos = gnome.position + gnome.size/2 + rl.Vector2Rotate({150, 0}, angle)
            rl.DrawRectangleV(hookPos - {10,10}, {20, 20}, rl.RED)
        } else { 
            hookPos = gnome.position + gnome.size/2 + rl.Vector2Rotate({-150, 0}, -angle)
            rl.DrawRectangleV(hookPos - {10,10}, {20, 20}, rl.RED)
        }
        a, b := find_line(hookPos, gnome.position + gnome.size/2)
        for i := f32(0); i < 1600; i += 10 {
            j := a * i + b 
               rl.DrawCircleV({i, j}, 2, rl.GRAY)
        }
    } else do time = 0 //math.PI 
    if rl.IsKeyReleased(rl.KeyboardKey.X) && hooked == false {
        for i := 0; i < len(bricks); i+=1 {
            needPoint, hooked = draw_hook(hookPos, &gnome, bricks[i])
        
            hookLength = rl.Vector2Length(actual_needed_point(i)-gnome.position-gnome.size/2)
        
            if hooked == true {
                hookedBrick = i
                break   
            }
        }        
    }
}

render :: proc() {
    using state
    
    rl.BeginDrawing()
    rl.BeginMode2D(cam)   
    rl.ClearBackground(rl.RAYWHITE)
   
    if hooked == true {
        rl.DrawLineV(gnome.position + gnome.size/2, actual_needed_point(hookedBrick), rl.GREEN)
    }

    for i := 0; i < len(bricks); i += 1 {
        rl.DrawRectangleV(bricks[i].position, bricks[i].size, bricks[i].color)
    }
    if !gnome.prepJump { 
        if look == .right do rl.DrawTextureV(gnome_tex, gnome.position, rl.WHITE)
        else do rl.DrawTextureRec(gnome_tex, {gnome.size.x, 0, gnome.size.x, gnome.size.y}, gnome.position, rl.WHITE)
    } else {
        stretch := (gnome.jumpPower-2)/(PLAYER_POWER_MAX-2)
        destination := rl.Rectangle {gnome.position.x-(stretch/2)*50, gnome.position.y+(stretch/2)*100, (1+stretch/2)*100, (1-stretch/2)*100}
        if look == .right {
            rl.DrawTexturePro(gnome_tex, 
                {0, 0, 100, 100}, 
                destination,
                {0,0}, 
                0, 
                rl.WHITE
            )
        } else {
            rl.DrawTexturePro(gnome_tex,
                {gnome.size.x, 0, gnome.size.x, gnome.size.y}, 
                destination, 
                {0,0}, 
                0, 
                rl.WHITE
            )
        }
    }
    rl.DrawLineV(gnome.position + gnome.size/2, gnome.position + gnome.size/2 + gnome.moveDirection*100, rl.PURPLE)
    rl.DrawText("Congrats! You created your first window!", 190, 200, 50, rl.LIGHTGRAY)

    rl.EndMode2D()

    rl.DrawFPS(20,20)
    rl.DrawText("Gnome:", 20, 80, 40, rl.BLACK)    
    rl.DrawText(fmt.caprintf("%v",gnome.position.x), 20, 140, 40, rl.BLACK)    
    rl.DrawText(fmt.caprintf("%v",gnome.position.y), 20, 180, 40, rl.BLACK) 
    rl.DrawText(fmt.caprintf("%v",gnome.moveDirection), 20, 220, 40, rl.BLACK) 
    rl.DrawText(fmt.caprintf("%v",gnome.canJump), 20, 260, 40, rl.BLACK) 
    
    rl.EndDrawing()
}

actual_needed_point :: proc(i : int) -> rl.Vector2 {    
    return state.needPoint + state.bricks[i].position
}

actual_gnome_position :: proc() -> rl.Vector2 {
    return state.gnome.position + state.gnome.size/2
}

update :: proc() {
    using state

    if gnome.canJump != -2 {
        gnome.moveDirection += {0,1}*deltaTime*9.8
        gnome.position += PLAYER_SPD*gnome.moveDirection*deltaTime    
    }
    bricks[1].position.y = cast(f32) math.sin(rl.GetTime())*200+500
    bricks[2].position.x = cast(f32) math.cos(rl.GetTime())*200+700

    if gnome.canJump >= 0 {
        gnome.position.y = bricks[gnome.canJump].position.y - gnome.size.y   
        gnome.position.x += bricks[gnome.canJump].position.x - bricksPos[gnome.canJump].x
    } 
    // gnome.canJump = -1
    
    vect := actual_gnome_position() - actual_needed_point(hookedBrick)   
    
    if rl.Vector2Length(vect) >= hookLength && hooked == true && gnome.canJump == -1 {
        gnome.canJump = -2
        hookAngle = rl.Vector2Angle(vect, {1,0})
        
        hookAngleVelocity = 0.02 * -math.sign(gnome.moveDirection.x)*rl.Vector2Length(gnome.moveDirection)
        if gnome.position.y < actual_needed_point(hookedBrick).y {
            hookAngle *= -1
        }
        
        fmt.printf("hookAngleV: %v\n", hookAngle/math.PI*180)
        
    }
    if gnome.canJump == -2 {
        hookAngleAcceleration := 0.2 * math.cos(hookAngle) * rl.GetFrameTime()
        hookAngleVelocity += hookAngleAcceleration
        hookAngle += hookAngleVelocity
        hookAngleVelocity *= 0.99 

        gnome.position.x = -gnome.size.x/2 + actual_needed_point(hookedBrick).x + math.cos(hookAngle) * hookLength
        gnome.position.y = -gnome.size.y/2 + actual_needed_point(hookedBrick).y + math.sin(hookAngle) * hookLength
    }
    if rl.Vector2Length(vect) >= hookLength && hooked == true && gnome.canJump > -1 {
        hookLenNow := rl.Vector2Length(vect)
        hookNeededLen := (hookLenNow - hookLength) * rl.Vector2Normalize(-vect)
        gnome.position.x += hookNeededLen.x         
    } 
    // rl.DrawLineV(actual_needed_point(hookedBrick), actual_needed_point(hookedBrick)+vect, rl.BLUE)
    if gnome.canJump > -2 do gnome.canJump = -1
    
    for i := 0; i < len(bricks); i+=1 {
        coll := resolve_collision(&gnome, bricks[i])
        switch coll {
            case .top: gnome.canJump = i
            case .other: hookAngleVelocity = 0
            case .none: 
        } 
    }
    
    for i := 0; i < len(bricks); i+=1 {
        bricksPos[i] = bricks[i].position
    }
    fmt.printf("MOVE DIR: %v\n",gnome.moveDirection)
    cam.target = math.lerp(cam.target, actual_gnome_position(), f32(0.2))   
}


Look_Dir :: enum {right, left}
 
Collision_Side :: enum {top, none, other}

find_line :: proc(p1: rl.Vector2, p2: rl.Vector2) -> (a: f32, b: f32) {
    a = (p2.y - p1.y) / (p2.x - p1.x)
    b = p1.y - a * p1.x
    return a, b
}

main :: proc() {
    using state
    
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Gnome")
    rl.InitAudioDevice()
    rl.SetTargetFPS(60)
     
    cam.target = actual_gnome_position()
    cam.offset = rl.Vector2 {SCREEN_WIDTH/2, SCREEN_HEIGHT/2}
    cam.rotation = 0
    cam.zoom = 1
    
    // Gnome texture    
    load_texture()
    
    // Gnome sounds
    load_sound()
    
    for !rl.WindowShouldClose() {
        deltaTime = rl.GetFrameTime()
        if deltaTime > 0.05 do deltaTime = 0.05
        user_input()
        update()
        render()
    }

    rl.CloseWindow()
}
