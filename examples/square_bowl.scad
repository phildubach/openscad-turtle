use <../turtle.scad>;

BOWL = [80, 60, 20]; // outer dimensions of the bowl

CORNER_R = 10;    // bowl radius

WALL = 3;       // wall thickness
RO = 5;         // outer radius
RI = 3;         // inner radius

GROOVE_H = 15;  // center height of decorative groove
GRmin = 0.5;    // minor groove radius
GRmaj = 1;      // major groove radius

$fn = $preview ? 32 : 128;

module cross_section(width) {
    turtle([
        t_elastic_line(), // line of unknown length in X direction
        t_left(45),        // turn left 45 degrees for 3D printability
        t_left(45, RO),    // arc to outer radius
        t_stretch_to_X(width),  // now adjust the elastic line to make X = D/2
        // begin decorative groove
        t_elastic_line(), // line of unknown length in Y direction
        t_left(45, 0.5),   // arc into the wall 45 degrees
        t_right(45, 1),    // draw half the decorative groove
        t_stretch_to_Y(GROOVE_H),   // now adjust the elastic line to groove height
        t_right(45, 1),    // draw the other half of the decorative groove
        t_left(45, 0.5),   // arc back to the outer wall 45 degrees
        // end decorative groove
        t_along_Y_to(BOWL.z-WALL/2), // move to the top of the bowl minux lip height
        t_left(180, WALL/2), // draw the lip
        t_elastic_line(), // line of unknown length in -Y direction
        t_right(90, RI),   // draw the inner radius
        t_stretch_to_Y(WALL), // now adjust the elastic line to make Y = WALL
        t_along_X_to(0),    // complete the inner bottom of the bowl
    ]);
}

module bowl() {
    // longer sides
    for (rz = [90, -90])
        rotate([90, 0, rz])
            linear_extrude(height = BOWL.x-2*CORNER_R, center = true)
                cross_section(BOWL.y/2);
    // shorter sides
    for (rz = [0, 180])
        rotate([90, 0, rz])
            linear_extrude(height = BOWL.y-2*CORNER_R, center = true)
                cross_section(BOWL.x/2);
    // rounded corners
    for (i = [0 : 3]) {
        dx = (BOWL.x/2 - CORNER_R) * (i > 0 && i < 3 ? -1 : 1);
        dy = (BOWL.y/2 - CORNER_R) * (i < 2 ? 1 : -1);
        translate([dx, dy, 0])
            rotate([0, 0, i*90])
                rotate_extrude(angle=90) cross_section(CORNER_R);
    }
}

bowl();
