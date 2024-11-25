use <../turtle.scad>;

BOWL_D = 80;    // outer diameter of the bowl
BOWL_H = 20;    // outer height of the bowl

WALL = 3;       // wall thickness
RO = 5;         // outer radius
RI = 3;         // inner radius
GROOVE_H = 15;  // center height of decorative groove
GRmin = 0.5;    // minor groove radius
GRmaj = 1;      // major groove radius

$fn = $preview ? 32 : 128;

rotate_extrude($fn=128) {
    turtle([
        t_elastic_line(),
        t_left(45),
        t_left(45, RO),
        t_stretch_to_X(BOWL_D/2),
        // begin decorative groove
        t_elastic_line(),
        t_left(45, 0.5),
        t_right(45, 1),
        t_stretch_to_Y(GROOVE_H),
        t_right(45, 1),
        t_left(45, 0.5),
        // end decorative groove
        t_along_Y_to(BOWL_H-WALL/2), // move to the top of the bowl minux lip height
        t_left(180, WALL/2), // draw the lip
        t_elastic_line(),
        t_right(90, RI),
        t_stretch_to_Y(WALL), // now adjust the variable line to make Y = WALL
        t_along_X_to(0),    // complete the inner bottom of the bowl
    ]);
}
