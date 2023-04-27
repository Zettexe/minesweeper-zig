//
// minesweeper
// Zig version: 0.1.0
// Author: Zettexe
// Date: 2023-04-20
//

const rl = @import("raylib");
const std = @import("std");

const draw_debug = true;

const Vector2Int = struct {
    x: c_int,
    y: c_int,
};

// Maybe I should use a font for this instead
// but I dont want to learn that right now
const number_texture_map = [10]rl.Rectangle{
    rl.Rectangle{ .x = 24, .y = 21, .width = 4, .height = 5 }, // 0
    rl.Rectangle{ .x = 19, .y = 27, .width = 4, .height = 5 }, // 1
    rl.Rectangle{ .x = 24, .y = 27, .width = 4, .height = 5 }, // 2
    rl.Rectangle{ .x = 29, .y = 27, .width = 4, .height = 5 }, // 3
    rl.Rectangle{ .x = 19, .y = 33, .width = 4, .height = 5 }, // 4
    rl.Rectangle{ .x = 24, .y = 33, .width = 4, .height = 5 }, // 5
    rl.Rectangle{ .x = 29, .y = 33, .width = 4, .height = 5 }, // 6
    rl.Rectangle{ .x = 19, .y = 39, .width = 4, .height = 5 }, // 7
    rl.Rectangle{ .x = 24, .y = 39, .width = 4, .height = 5 }, // 8
    rl.Rectangle{ .x = 29, .y = 39, .width = 4, .height = 5 }, // 9
};

pub fn main() anyerror!void {
    // Initialization
    // ---------------------------------------------------------------------------------

    const initial_window_width: c_int = 1280;
    const initial_window_height: c_int = 720;

    rl.SetConfigFlags(rl.ConfigFlags.FLAG_WINDOW_RESIZABLE);
    // rl.SetConfigFlags(rl.ConfigFlags.FLAG_VSYNC_HINT);
    // rl.SetConfigFlags(rl.ConfigFlags.FLAG_WINDOW_UNDECORATED);
    rl.InitWindow(initial_window_width, initial_window_height, "Minesweeper");
    defer rl.CloseWindow();

    // rl.MaximizeWindow();
    rl.SetTargetFPS(120);

    // ---------------------------------------------------------------------------------
    const tile_size = 9;
    const border_offset: c_int = 3;
    const grid_size_x: c_int = 16;
    const grid_size_y: c_int = 16;

    const toolbar_width = 16 + border_offset * 2;

    const screen_width: c_int = tile_size * grid_size_x + border_offset * 2 + toolbar_width;
    const screen_height: c_int = tile_size * grid_size_y + border_offset * 2;

    var target = rl.LoadRenderTexture(screen_width, screen_height);
    rl.SetTextureFilter(target.texture, @enumToInt(rl.TextureFilter.TEXTURE_FILTER_POINT)); // Texture scale filter to use

    const screen_width_float = @as(f32, screen_width);
    const screen_height_float = @as(f32, screen_height);

    var sprites = rl.LoadTexture("assets/sprites.png");

    var prev_tile_mouse_position = Vector2Int{ .x = 0, .y = 0 };

    var mines: usize = 40;
    var temp: usize = 0;

    // Main game loop
    while (!rl.WindowShouldClose()) {
        // Update
        //---------------------------------------------------------------------------------
        const window_width = @intToFloat(f32, rl.GetScreenWidth());
        const window_height = @intToFloat(f32, rl.GetScreenHeight());

        const scale = @min(window_width / screen_width_float, window_height / screen_height_float);

        const mouse_position = rl.GetMousePosition();
        const v_mouse_x = (mouse_position.x - (window_width - (screen_width_float * scale)) * 0.5) / scale;
        const v_mouse_y = (mouse_position.y - (window_height - (screen_height_float * scale)) * 0.5) / scale;
        const virtual_mouse_position = rl.Vector2{ .x = std.math.clamp(v_mouse_x, 0, screen_width_float - 1), .y = std.math.clamp(v_mouse_y, 0, screen_height_float - 1) };

        var tile_mouse_position = prev_tile_mouse_position;

        if (!rl.IsMouseButtonDown(rl.MouseButton.MOUSE_BUTTON_LEFT)) {
            tile_mouse_position = Vector2Int{ .x = @divFloor(@floatToInt(c_int, virtual_mouse_position.x) - border_offset, tile_size), .y = @divFloor(@floatToInt(c_int, virtual_mouse_position.y) - border_offset, tile_size) };
            prev_tile_mouse_position = tile_mouse_position;
        }

        temp += 1;
        if (temp >= 10) {
            temp = 0;
            // mines += 1;
            if (mines >= 999) {
                mines = 0;
            }
        }

        const mines_3 = mines % 10;
        const mines_2 = (mines / 10) % 10;
        const mines_1 = (mines / 100) % 10;

        //---------------------------------------------------------------------------------

        // Draw
        //---------------------------------------------------------------------------------
        rl.BeginTextureMode(target);
        rl.ClearBackground(rl.WHITE); // Clear render texture background color

        DrawNineSlice(sprites, rl.Rectangle{ .x = 18, .y = 9, .width = 9, .height = 9 }, rl.Rectangle{ .x = 0, .y = 0, .width = screen_width_float, .height = screen_height_float }, 3, rl.WHITE, true);

        var y: usize = 0;
        while (y < grid_size_y) : (y += 1) {
            var x: usize = 0;
            while (x < grid_size_x) : (x += 1) {
                rl.DrawTextureRec(sprites, rl.Rectangle{ .x = 0, .y = 0, .width = tile_size, .height = tile_size }, rl.Vector2{ .x = @intToFloat(f32, tile_size * x + border_offset), .y = @intToFloat(f32, tile_size * y + border_offset) }, rl.WHITE);
            }
        }

        const display_height = 7 + border_offset * 2;
        const aspect_height = 7 + border_offset * 2;
        const right_edge = tile_size * grid_size_x + border_offset;
        DrawNineSlice(sprites, rl.Rectangle{ .x = 18, .y = 9, .width = 9, .height = 9 }, rl.Rectangle{ .x = right_edge, .y = right_edge - display_height, .width = toolbar_width, .height = display_height }, border_offset, rl.WHITE, false);
        DrawNineSlice(sprites, rl.Rectangle{ .x = 0, .y = 0, .width = 9, .height = 9 }, rl.Rectangle{ .x = right_edge, .y = right_edge - display_height - aspect_height, .width = toolbar_width, .height = aspect_height }, border_offset, rl.WHITE, false);

        DrawNineSlice(sprites, rl.Rectangle{ .x = 0, .y = 0, .width = 9, .height = 9 }, rl.Rectangle{ .x = right_edge, .y = border_offset, .width = toolbar_width, .height = tile_size * grid_size_y - display_height - aspect_height }, border_offset, rl.WHITE, false);

        rl.DrawTextureRec(sprites, number_texture_map[mines_1], rl.Vector2{ .x = tile_size * grid_size_x + border_offset * 2 + 1, .y = screen_height - border_offset * 2 - 6 }, if (mines_1 == 0) rl.Color{ .r = 50, .g = 0, .b = 0, .a = 255 } else rl.RED);
        rl.DrawTextureRec(sprites, number_texture_map[mines_2], rl.Vector2{ .x = tile_size * grid_size_x + border_offset * 2 + 6, .y = screen_height - border_offset * 2 - 6 }, if (mines_1 == 0 and mines_2 == 0) rl.Color{ .r = 50, .g = 0, .b = 0, .a = 255 } else rl.RED);
        rl.DrawTextureRec(sprites, number_texture_map[mines_3], rl.Vector2{ .x = tile_size * grid_size_x + border_offset * 2 + 11, .y = screen_height - border_offset * 2 - 6 }, if (mines_1 == 0 and mines_2 == 0 and mines_3 == 0) rl.Color{ .r = 50, .g = 0, .b = 0, .a = 255 } else rl.RED);

        if (tile_mouse_position.x >= 0 and tile_mouse_position.y >= 0 and tile_mouse_position.x < grid_size_x and tile_mouse_position.y < grid_size_y) {
            rl.DrawRectangle(tile_mouse_position.x * tile_size + border_offset, tile_mouse_position.y * tile_size + border_offset, tile_size, tile_size, rl.Color{ .r = 80, .g = 80, .b = 80, .a = 50 });
        }

        rl.EndTextureMode();
        // ---------------------------------------------------------------------------------

        // Raw Draw
        // ---------------------------------------------------------------------------------
        rl.BeginDrawing();

        rl.ClearBackground(rl.BLACK); // Clear background color

        const source_rect = rl.Rectangle{ .x = 0, .y = 0, .width = @intToFloat(f32, target.texture.width), .height = @intToFloat(f32, -target.texture.height) };
        const destination_rect = rl.Rectangle{ .x = (window_width - (screen_width_float * scale)) * 0.5, .y = (window_height - (screen_height_float * scale)) * 0.5, .width = screen_width_float * scale, .height = screen_height_float * scale };
        rl.DrawTexturePro(target.texture, source_rect, destination_rect, rl.Vector2{ .x = 0, .y = 0 }, 0, rl.WHITE);

        if (draw_debug) {
            const text_position_x = 1;
            const text_position_y = 1;
            const font_size = 20;
            const debug_text1 = rl.TextFormat("Mouse Pos: [%i , %i]", @floatToInt(c_int, virtual_mouse_position.x), @floatToInt(c_int, virtual_mouse_position.y));
            const debug_text2 = rl.TextFormat("Tile  Pos: [%i , %i]", tile_mouse_position.x, tile_mouse_position.y);

            rl.DrawFPS(text_position_x + 1, text_position_y + 1);
            rl.DrawText(debug_text1, text_position_x + 1, text_position_y + font_size + 1, font_size, rl.GREEN);
            rl.DrawText(debug_text2, text_position_x + 1, text_position_y + font_size * 2 + 1, font_size, rl.YELLOW);
        }

        rl.EndDrawing();
        // ---------------------------------------------------------------------------------
    }

    // De-Initialization
    // ---------------------------------------------------------------------------------
    rl.CloseWindow(); // Close window and OpenGL context
    // ---------------------------------------------------------------------------------
}

fn DrawNineSlice(texture: rl.Texture2D, sourceRect: rl.Rectangle, destRect: rl.Rectangle, borderSize: f32, color: rl.Color, skip_content_draw: bool) void {
    const srcTopLeft = rl.Rectangle{ .x = sourceRect.x, .y = sourceRect.y, .width = borderSize, .height = borderSize };
    const srcTopRight = rl.Rectangle{ .x = sourceRect.x + sourceRect.width - borderSize, .y = sourceRect.y, .width = borderSize, .height = borderSize };
    const srcBottomLeft = rl.Rectangle{ .x = sourceRect.x, .y = sourceRect.y + sourceRect.height - borderSize, .width = borderSize, .height = borderSize };
    const srcBottomRight = rl.Rectangle{ .x = sourceRect.x + sourceRect.width - borderSize, .y = sourceRect.y + sourceRect.height - borderSize, .width = borderSize, .height = borderSize };
    const srcTop = rl.Rectangle{ .x = sourceRect.x + borderSize, .y = sourceRect.y, .width = sourceRect.width - 2 * borderSize, .height = borderSize };
    const srcBottom = rl.Rectangle{ .x = sourceRect.x + borderSize, .y = sourceRect.y + sourceRect.height - borderSize, .width = sourceRect.width - 2 * borderSize, .height = borderSize };
    const srcLeft = rl.Rectangle{ .x = sourceRect.x, .y = sourceRect.y + borderSize, .width = borderSize, .height = sourceRect.height - 2 * borderSize };
    const srcRight = rl.Rectangle{ .x = sourceRect.x + sourceRect.width - borderSize, .y = sourceRect.y + borderSize, .width = borderSize, .height = sourceRect.height - 2 * borderSize };

    const destTopLeft = rl.Rectangle{ .x = destRect.x, .y = destRect.y, .width = borderSize, .height = borderSize };
    const destTopRight = rl.Rectangle{ .x = destRect.x + destRect.width - borderSize, .y = destRect.y, .width = borderSize, .height = borderSize };
    const destBottomLeft = rl.Rectangle{ .x = destRect.x, .y = destRect.y + destRect.height - borderSize, .width = borderSize, .height = borderSize };
    const destBottomRight = rl.Rectangle{ .x = destRect.x + destRect.width - borderSize, .y = destRect.y + destRect.height - borderSize, .width = borderSize, .height = borderSize };
    const destTop = rl.Rectangle{ .x = destRect.x + borderSize, .y = destRect.y, .width = destRect.width - 2 * borderSize, .height = borderSize };
    const destBottom = rl.Rectangle{ .x = destRect.x + borderSize, .y = destRect.y + destRect.height - borderSize, .width = destRect.width - 2 * borderSize, .height = borderSize };
    const destLeft = rl.Rectangle{ .x = destRect.x, .y = destRect.y + borderSize, .width = borderSize, .height = destRect.height - 2 * borderSize };
    const destRight = rl.Rectangle{ .x = destRect.x + destRect.width - borderSize, .y = destRect.y + borderSize, .width = borderSize, .height = destRect.height - 2 * borderSize };

    const origin = rl.Vector2{ .x = 0, .y = 0 };

    rl.DrawTexturePro(texture, srcTopLeft, destTopLeft, origin, 0, color);
    rl.DrawTexturePro(texture, srcTopRight, destTopRight, origin, 0, color);
    rl.DrawTexturePro(texture, srcBottomLeft, destBottomLeft, origin, 0, color);
    rl.DrawTexturePro(texture, srcBottomRight, destBottomRight, origin, 0, color);
    rl.DrawTexturePro(texture, srcTop, destTop, origin, 0, color);
    rl.DrawTexturePro(texture, srcBottom, destBottom, origin, 0, color);
    rl.DrawTexturePro(texture, srcLeft, destLeft, origin, 0, color);
    rl.DrawTexturePro(texture, srcRight, destRight, origin, 0, color);

    if (!skip_content_draw) {
        const srcCenter = rl.Rectangle{ .x = sourceRect.x + borderSize, .y = sourceRect.y + borderSize, .width = sourceRect.width - 2 * borderSize, .height = sourceRect.height - 2 * borderSize };
        const destCenter = rl.Rectangle{ .x = destRect.x + borderSize, .y = destRect.y + borderSize, .width = destRect.width - 2 * borderSize, .height = destRect.height - 2 * borderSize };
        rl.DrawTexturePro(texture, srcCenter, destCenter, origin, 0, color);
    }
}
