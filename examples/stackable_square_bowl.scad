use <../turtle.scad>;

BOWL = [80, 60, 25]; // outer dimensions of the bowl

CORNER_R = 10;    // bowl radius

WALL = 3;       // wall thickness
RO = 5;         // outer radius
RI = 3;         // inner radius

GROOVE_H = BOWL.z - 5;  // center height of decorative groove
GRmin = 0.5;    // minor groove radius
GRmaj = 1;      // major groove radius

GAP = 0.2;

$fn = $preview ? 32 : 128;

module cross_section(width) {
    turtle([
        t_elastic_line(), // line of unknown length in X direction
        t_left(45),        // turn left 45 degrees for 3D printability
        t_left(45, RO),    // arc to bottom protrusion
        t_stretch_to_X(width-WALL-GAP),  // now adjust the elastic line to set X
                                         // subtract WALL and GAP from width for stackability
        t_right(45, WALL/2), // arc out with r=WALL/2 to match the lip radius
        t_elastic_line(), // line of unknown length 45 degrees up and out
        t_left(45, RO),    // arc to outer wall
        t_stretch_to_X(width),  // now adjust the elastic line to make X = width
        t_store(0), // store current position and heading (index 0)
        // begin decorative groove
        t_elastic_line(), // line of unknown length in Y direction
        t_left(45, 0.5),   // arc into the wall 45 degrees
        t_right(45, 1),    // draw half the decorative groove
        t_stretch_to_Y(GROOVE_H),   // now adjust the elastic line to groove height
        t_right(45, 1),    // draw the other half of the decorative groove
        t_left(45, 0.5),   // arc back to the outer wall 45 degrees
        // end decorative groove
        t_along_Y_to(BOWL.z-WALL/2), // move to the top of the bowl minus lip height
        t_left(180, WALL/2), // draw the rounded lip with r = WALL/2
        t_along_Y_to("Y0"), // refer to Y coordinate of previously stored position 0
        t_right(45, RI),   // draw the first half of the inner radius
        t_elastic_line(),  // add a 45 degree line to avoid 
        t_right(45, RI),
        t_stretch_to_Y(WALL),
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