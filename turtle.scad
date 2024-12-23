// Turtle graphics library for OpenSCAD

// Draw a line of the given length using the current heading
function t_line(length) = [TURTLE_CMD_LINE, length];
// Rotate the turtle by the given angle (CCW)
function t_rotate(rel_angle) = [TURTLE_CMD_ROTATE, rel_angle];
// Rotate the turtle to the given absolute heading
function t_rotate_to(abs_angle) = [TURTLE_CMD_ROTATE_TO, abs_angle];
// Draw an arc with the given radius and angle (CCW)
function t_arc(angle, radius) = [TURTLE_CMD_ARC, angle, radius];
// Draw parallel to the X axis to absolute x_value (changes heading)
function t_along_X_to(x_value) = [TURTLE_CMD_ALONG_X_TO, x_value];
// Draw parallel to the Y axis to absolute y_value (changes heading)
function t_along_Y_to(y_value) = [TURTLE_CMD_ALONG_Y_TO, y_value];
// Draw a line using the current heading until X matches x_value
function t_line_to_X(x_value) = [TURTLE_CMD_LINE_TO_X, x_value];
// Draw a line using the current heading until Y matches y_value
function t_line_to_Y(y_value) = [TURTLE_CMD_LINE_TO_Y, y_value];
// Draw a line to the given absolute coordinates (changes heading)
function t_line_to(x_value, y_value) = [TURTLE_CMD_LINE_TO, x_value, y_value];

// Alias of t_arc(-rel_angle, radius) if radius given, otherwise t_rotate(-rel_angle)
function t_right(rel_angle, radius = 0) = radius == 0 ? t_rotate(-rel_angle) : t_arc(-rel_angle, radius);
// Alias of t_arc(+rel_angle, radius) if radius given, otherwise t_rotate(+rel_angle)
function t_left(rel_angle, radius = 0) = radius == 0 ? t_rotate(rel_angle) : t_arc(rel_angle, radius);

// Draw a line of yet unknown length using the current heading
function t_elastic_line() = [TURTLE_CMD_ELASTIC_LINE];
// Stretch the previous elastic line until X matches x_value
function t_stretch_to_X(x_value) = [TURTLE_CMD_STRETCH_TO_X, x_value];
// Stretch the previous elastic line until Y matches y_value
function t_stretch_to_Y(y_value) = [TURTLE_CMD_STRETCH_TO_Y, y_value];

// Store the current position and heading for later use
function t_store(idx=undef) = [TURTLE_CMD_STORE, idx];

/*
 * Turtle graphics module for 2D drawing
 *
 * Draws closed polygons by processing a list of movement commands.
 *
 * The turtle starts at [0,0] heading 0 degrees (along X axis, right).
 * If the polygon is not closed, the last point will be connected to the origin
 * [0,0]. Positive angles are counter-clockwise.
 */
module turtle(commands, debug=false) {
    // Function to get the correction vector for a point
    function get_corr(point, corr) =
        let(
            has_corr_data = len(point) > 2,
            has_length = len(point) > 3,
            heading = has_corr_data ? point[2] : 0,
            length = has_length ? point[3] : 0
        )
        has_length ? [length * cos(heading), length * sin(heading)] :
        has_corr_data ? corr :
        [0, 0]; // Default correction

    // Function to process the list of commands and generate points
    function turtle_path(commands, pos = [0, 0], heading = 0, corr = [], save = [], acc = [[0,0]]) =
        len(commands) == 0
        ? acc
        : let(
            cmd = commands[0],
            ncmds = len(commands),
            rest = ncmds < 2 ? [] : [for (i = [1 : 1 : ncmds - 1]) commands[i]],
            result = process_command(cmd, pos, heading, corr, save),
            new_pos = result[0],
            new_heading = result[1],
            new_points = result[2],
            new_corr = result[3],
            new_save = result[4],
            new_acc = concat(acc, new_points)
        )
        turtle_path(rest, new_pos, new_heading, new_corr, new_save, new_acc);

    // Function to process a single command
    function process_command(cmd, pos, heading, corr, save) =
        cmd[0] == TURTLE_CMD_LINE  ? process_line(cmd[1], pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_ROTATE  ? [pos, heading + cmd[1], [], corr, save] :
        cmd[0] == TURTLE_CMD_ROTATE_TO ? [pos, recall(save, cmd[1]), [], corr, save] :
        cmd[0] == TURTLE_CMD_ARC  ? process_arc(cmd[1], cmd[2], pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_ALONG_X_TO  ? process_along_x_to(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_ALONG_Y_TO  ? process_along_y_to(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_LINE_TO_X ? process_line_to_X(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_LINE_TO_Y ? process_line_to_Y(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_LINE_TO ? process_line_to(recall(save, cmd[1]), recall(save, cmd[2]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_ELASTIC_LINE ? process_elastic_line(pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_STRETCH_TO_X ? process_stretch_to_X(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_STRETCH_TO_Y ? process_stretch_to_Y(recall(save, cmd[1]), pos, heading, corr, save) :
        cmd[0] == TURTLE_CMD_STORE ? process_store(cmd[1], pos, heading, corr, save) :
        assert(false, "Unknown command");

    function process_store(idx, pos, heading, corr, save) =
        let (
            index = idx == undef ? len(save) : idx
        )
        assert(len(corr) == 0, "Cannot store position with pending elastic line")
        assert(index == len(save), "Optional store index must be incremental")
        [pos, heading, [], corr, concat(save, [[pos, heading]])];

    // Function to process a line command
    function process_line(length, pos, heading, corr, save) =
        let(
            rad = heading,
            delta = [length * cos(rad), length * sin(rad)],
            new_pos = pos + delta,
            // Include correction data if present
            new_points = [concat(pos, corr), concat(new_pos, corr)]
        )
        [new_pos, heading, new_points, corr, save];

    // Function to process an arc command
    function process_arc(angle, radius, pos, heading, corr, save) =
        let(
            delta_heading = angle,
            rad = heading,
            // Adjust center based on the sign of the angle
            center = pos + radius * [-sin(rad), cos(rad)] * sign(delta_heading),
            // Start angle calculation (angles in degrees)
            start_angle = atan2(pos[1] - center[1], pos[0] - center[0]),
            // Determine number of steps
            n_steps_fn = $fn > 0 ? ceil(abs(delta_heading) * $fn / 360) : 0,
            n_steps_fa = $fa > 0 ? ceil(abs(delta_heading) / $fa) : 0,
            n_steps = max(n_steps_fn, n_steps_fa, 1),
            // Generate angles
            angles = [
                for (i = [0 : n_steps])
                    start_angle + delta_heading * i / n_steps
            ],
            // Generate points along the arc, including correction data
            points = [
                for (a = angles)
                    concat(center + radius * [cos(a), sin(a)], corr)
            ],
            last_point = points[len(points) - 1],
            new_pos = [last_point[0], last_point[1]],
            new_heading = heading + delta_heading
        )
        [new_pos, new_heading, points, corr, save];

    // Function to move to a specific X coordinate
    function process_along_x_to(x_value, pos, heading, corr, save) =
        let(
            delta_x = x_value - pos[0],
            new_heading = delta_x >= 0 ? 0 : 180,
            length = abs(delta_x)
        )
        process_line(length, pos, new_heading, corr, save);

    // Function to move to a specific Y coordinate
    function process_along_y_to(y_value, pos, heading, corr, save) =
        let(
            delta_y = y_value - pos[1],
            new_heading = delta_y >= 0 ? 90 : -90,
            length = abs(delta_y)
        )
        process_line(length, pos, new_heading, corr, save);

    // Function to draw a line until X reaches a specific value
    function process_line_to_X(x_value, pos, heading, corr, save) =
        let(
            rad = heading,
            cos_h = cos(rad),
            length = abs(cos_h) < 1e-6 ? 0 : (x_value - pos[0]) / cos_h
        )
        process_line(length, pos, heading, corr, save);

    // Function to draw a line until Y reaches a specific value
    function process_line_to_Y(y_value, pos, heading, corr, save) =
        let(
            rad = heading,
            sin_h = sin(rad),
            length = abs(sin_h) < 1e-6 ? 0 : (y_value - pos[1]) / sin_h
        )
        process_line(length, pos, heading, corr, save);

    // Function to draw a line to a specific (x, y) coordinate and calculate the heading
    function process_line_to(x_value, y_value, pos, heading, corr, save) =
        let(
            delta = [x_value - pos[0], y_value - pos[1]],
            length = sqrt(delta[0]^2 + delta[1]^2),
            new_heading = atan2(delta[1], delta[0])
        )
        assert(length(corr) == 0, "Cannot draw line to specific point with pending elastic line")
        process_line(length, pos, heading, corr, save);

    function process_elastic_line(pos, heading, corr, save) =
        assert(len(corr) == 0, "Must stretch previous elastic line before starting a new one")
        [pos, heading, [concat(pos, [heading])], [heading], save];

    function process_stretch_to_X(x_value, pos, heading, corr, save) =
        let(
            delta_x = x_value - pos[0],
            // Avoid division by zero
            cos_corr = cos(corr[0]),
            length = abs(cos_corr) < 1e-6 ? 0 : delta_x / cos_corr,
            // Calculate correction data [heading, length]
            corr_data = [corr[0], length],
            delta_y = delta_x * tan(corr[0]),
            new_pos = [x_value, pos[1] + delta_y]
        )
        [new_pos, heading, [concat(new_pos, corr_data)], [], save];

    function process_stretch_to_Y(y_value, pos, heading, corr, save) =
        let(
            delta_y = y_value - pos[1],
            // Avoid division by zero
            sin_corr = sin(corr[0]),
            length = abs(sin_corr) < 1e-6 ? 0 : delta_y / sin_corr,
            // Calculate correction data [heading, length]
            corr_data = [corr[0], length],
            delta_x = delta_y / tan(corr[0]),
            new_pos = [pos[0] + delta_x, y_value]
        )
        [new_pos, heading, [concat(new_pos, corr_data)], [], save];

    // Generate the list of points by processing the commands
    points = turtle_path(commands);

    if (debug) echo("points", points);
    pLen = len(points);

    // Apply corrections in reverse order
    corr_points = [
        for (i = pLen - 1, corr = [0, 0]; i >= 0;
             corr = get_corr(points[i], corr), i = i - 1)
            [points[i][0], points[i][1]] + (len(points[i]) > 2 ? corr : [0,0])
    ];

    // Reverse the points back to original order
    reversed_points = [for (i = [len(corr_points) - 1 : -1 : 0]) corr_points[i]];

    // remove duplicates from final_points
    final_points = [for (i = [0 : len(reversed_points) - 1])
        if (i == 0 || reversed_points[i] != reversed_points[i - 1])
            reversed_points[i]
    ];

    // Output the points for debugging
    if (debug) echo("Resulting final_points:", final_points);

    // Draw the polygon using the generated points
    polygon(final_points);
}

function strtoint (s, ret=0, i=0) =
  i >= len(s)
  ? ret
  : strtoint(s, ret*10 + ord(s[i]) - ord("0"), i+1);

function get_param(param, poshead) =
    param == "X" ? poshead[0][0] :
    param == "Y" ? poshead[0][1] :
    param == "H" ? poshead[1] :
    assert(false, "Unknown parameter");

/* Resolve a value used as a command argument.
 * If the value is an integer, simply return it.
 * save is a list of saved positions in the format [[x, y], heading].
 * If it is a string, perform a lookup as follows:
* 'X0' refers to the X coordinate of the saved position 0
*      and thus we return saved[0][0][0]
* 'Y0' is saved[0][0][1]
* 'H0' is saved[0][1]
*/
function recall(save, value) =
    is_num(value) ? value :
    let(
        idx = strtoint(value, i=1),
        param = value[0],
        pos = save[idx]
    )
    get_param(param, pos);

// When sourced via `include`, these constants are exposed, even though they are
// for internal library use only. Ideally, use `use <turtle.scad>` to avoid
// polluting the global namespace.
TURTLE_CMD_LINE = 0;
TURTLE_CMD_ROTATE = 1;
TURTLE_CMD_ROTATE_TO = 2;
TURTLE_CMD_ARC = 3;
TURTLE_CMD_ALONG_X_TO = 4;
TURTLE_CMD_ALONG_Y_TO = 5;
TURTLE_CMD_LINE_TO_X = 6;
TURTLE_CMD_LINE_TO_Y = 7;
TURTLE_CMD_LINE_TO = 8;
TURTLE_CMD_ELASTIC_LINE = 9;
TURTLE_CMD_STRETCH_TO_X = 10;
TURTLE_CMD_STRETCH_TO_Y = 11;
TURTLE_CMD_STORE = 12;

