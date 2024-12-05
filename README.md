# openscad-turtle

Turtle graphics library for OpenSCAD

## Command description

### Commands for drawing straight lines

* `t_line(length)`

   Draw a line of the specified length using the current turtle heading.

* `t_line_to_X(x_value)`

    Draw a line to the specified X coordinate using the current turtle heading.

* `t_line_to_Y(y_value)`

    Draw a line to the specified Y coordinate using the current turtle heading.

* `t_line_to(x_value, y_value)`

    Draw a line to the specified absolute X and Y coordinates. The turtle's
    heading is updated to indicate the direction of travel.

* `t_line_along_X_to(x_value)` /`t_line_along_Y_to(y_value)`

    Draw a line along the X/Y axis until the X/Y coordinate matches the given
    value. The turtle's heading is updated to the direction of travel.

### Commands for drawing arcs

* `t_arc(radius, rel_angle)`

    Draw an arc in the given direction using the given radius and relative angle.
    Positive angles rotate the turtle counter-clockwise.

* `t_left(radius, rel_angle)` / `t_right(radius, rel_angle)`

    These are aliases for `t_arc(radius, angle)` and `t_arc(radius, -angle)`
    When radius is 0 or omitted, nothing is drawn and the command is equivalent
    to `t_rotate(angle)` in the given direction.

## Commands for rotating the turtle in place

* `t_rotate(rel_angle)`

    Rotate the turtle by the specified angle in degrees (relative rotation).
    Positive angles rotate the turtle counter-clockwise.

* `t_rotate_to(abs_angle)`

    Set the turtle's heading to the specified angle in degrees (absolute
    rotation). The angle is measured counter-clockwise from the positive X
    axis direction.

* `t_right(rel_angle)` / `t_left(rel_angle)`

    These are aliases for `t_rotate(rel_angle)` and `t_rotate(-rel_angle)` respectively.

## Commands for elastic lines

Sometimes it is desirable to draw a line whose length is not known in advance.
The following commands allow you to draw elastic lines that can be stretched or
compressed after they are drawn.

* `t_elastic_line()`

    Draw an elastic line using the current heading. The line can later be
    stretched using the commands below. Uses the current turtle heading.

    **Important**: The elastic line must be stretched to a known position before
    another elastic line is drawn or a position is stored.

* `t_stretch_to_X(x_value)` / `t_stretch_to_Y(y_value)`

    Stretch the previous elastic line so that the turtle's X/Y coordinate
    matches the given value. The elastic line is stretched along the heading of
    the elastic line. The current heading is not affected.


## Commands for referring to previous turtle states

For some drawings, it can be useful to refer to the turtle's previous states.
For example, to place a feature at the same Y coordinate as a previous point.
Due to the use of arcs, the turtle's previous states are not necessarily
easy to calculate.

* `t_store()` / `t_store(index)`

    Stores the current position and heading of the turtle. Throughout the
    drawing, multiple positions can be stored. The first position will be
    stored in index 0, and the index increments for subsequent stores.

    Specifying an index is optional and when used, the library enforces that
    the first store uses index 0, and the index increments for subsequent
    stores. Using the index argument is for documentation only, so that readers
    of the code can easily see what position is being stored, without having to
    count invocations of the `t_store()` command.

    **Important**: Only fully resolved positions can be stored, i.e. if there
    is a pending elastic line, it must be stretched to a known position before
    `t_store()` is called.

Referring to previously stored positions:

Any function taking an `x_value`, `y_value` or `abs_angle` argument can also
take a reference string instead of a number.

Supported reference strings are:

* `"X<n>"` / `"Y<n>"`

    Refers to the X/Y coordinate of the stored position with index `<n>`, e.g.
    `"X0"` to refer to the X position of the first call of `t_store`.

* `"H<n>"`
    Refers to the heading of the stored position with index `<n>`.

> **NOTE**: The library currently does not enforce the reference type, so it is
possible to specify an `x_value` of `"H1"` or `"Y0"`. This likely does not make
much sense. Checks may be added in the future to avoid mixing references.
