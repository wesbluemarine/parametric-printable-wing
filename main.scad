include <lib/airfoil.scad>
include <lib/grid.scad>

// ----- Wing settings ----- 
$wing_length = 150;
$naca_airfoil = 0015;
$wing_chord_length = 75;
$tip_chord_ratio = 0.8;
$rib_grid_distance = $wing_chord_length / 4 / sqrt(2);
$airfoil_cutoff_chord_fraction = 0.98;

// ----- Structure settings ----- 
// For ribs running all the way through the wing, set this value very high (greater than then chord length).
$rib_thickness = 1.5;
$rib_center_support_cones_enabled = true;
$rib_center_support_cone_inersection_diameter = 3;
$rib_center_support_cone_angle = 40; // degrees

// ----- Spar settings ----- 
$spar_enabled = true;
$spar_diameter = 3.4;
$spar_count = 1
; // Number of spar holes
$spar_spacing_chord_fraction = 0.15; // Spacing between spar holes as a fraction of chord length
$spar_holding_structure_height_chord_fraction = 0.055;

// ----- Nitty gritty details ----- 
$center_gap = 0.9;
$rib_width = 0.1;
$wing_x_offset_chord_fraction = 0.002;

$grid_height = $wing_chord_length;
$rib_center_support_sections_length = $wing_chord_length;

// ----- Code -----

/// Structure grid
module generateStructureGrid() {
    $grid_diagonal_distance = $rib_grid_distance * sqrt(2);
    union()
    grid(ceil($wing_chord_length / $grid_diagonal_distance), ceil($wing_length / $grid_diagonal_distance) + 1, $grid_diagonal_distance)
    rotate([0, 45, 0])
    translate([0, -$grid_height / 2, 0])
    difference() {
        cube([$rib_grid_distance + $rib_width / 2, $grid_height, $rib_grid_distance + $rib_width / 2]);
        translate([$rib_width / 2, 0, $rib_width / 2])
        cube([$rib_grid_distance - $rib_width / 2, $grid_height, $rib_grid_distance - $rib_width / 2]);
    }
}

/// Wing
module generateWing2D() {
    intersection() {
        translate([0, -$wing_chord_length])
        square([$airfoil_cutoff_chord_fraction * $wing_chord_length, $wing_chord_length * 2]);
        airfoil_poly($wing_chord_length, $naca_airfoil);
    }
}

module generateWing() {
    linear_extrude(height = $wing_length, scale = [$tip_chord_ratio, $tip_chord_ratio])
        generateWing2D();
}

/// Spar
module generateSparStructureGap() {
    if ($spar_enabled)
    for (i = [0 : $spar_count - 1]) {
        position = (i + 1) * $spar_spacing_chord_fraction;
        if (position < 1) {
            translateToMclPoint($wing_chord_length, $naca_airfoil, position)
            linear_extrude(height = $wing_length, scale = [$tip_chord_ratio, $tip_chord_ratio])
            union() {
                offset(delta = 1)
                    circle(d=$spar_diameter, $fn=30);
                square(size = [2, $wing_chord_length*2], center=true);
            }
        }
    }
}

module generateSparStructure() {
    if ($spar_enabled)
    for (i = [0 : $spar_count - 1]) {
        position = (i + 1) * $spar_spacing_chord_fraction;
        if (position < 1) {
            translateToMclPoint($wing_chord_length, $naca_airfoil, position)
            linear_extrude(height = $wing_length, scale = [$tip_chord_ratio, $tip_chord_ratio])
            union() {
                circle(d=$spar_diameter, $fn=30);
                translate([0, -0.5, 0])
                translateFromMclToSurface($wing_chord_length, $naca_airfoil, position)
                translate([0, - $wing_chord_length, 0])
                square(size = [0.1, $wing_chord_length*2], center=true);
            }
        }
    }
}

/// Structure
module generateInnerStructureSupportCones() {
    $grid_diagonal_distance = $rib_grid_distance * sqrt(2) / 2;
    if ($rib_center_support_cones_enabled)
    mclFollowingGrid(
        $wing_chord_length,
        $naca_airfoil,
        ceil($wing_chord_length / $grid_diagonal_distance),
        ceil($wing_length / $grid_diagonal_distance) + 1,
        $grid_diagonal_distance
        )
    rotate([90, 0, 0])
    union() {
        mirror([0, 0 ,1])
        translate([0, 0, -$rib_center_support_sections_length])
        cylinder(h = $rib_center_support_sections_length, d1 = $rib_center_support_cone_inersection_diameter + 2 * tan($rib_center_support_cone_angle) * $rib_center_support_sections_length, d2 = $rib_center_support_cone_inersection_diameter, center = false);

        translate([0, 0, -$rib_center_support_sections_length])
        cylinder(h = $rib_center_support_sections_length, d1 = $rib_center_support_cone_inersection_diameter + 2 * tan($rib_center_support_cone_angle) * $rib_center_support_sections_length, d2 = $rib_center_support_cone_inersection_diameter, center = false);
    }
}

module generateInnerStructureCutout() {
    difference() {
        linear_extrude(height = $wing_length, scale = [$tip_chord_ratio, $tip_chord_ratio])
            offset(delta = -$rib_thickness)
                generateWing2D();
        generateInnerStructureSupportCones();
    }
}

module generateInnerStructure() {
    difference() {
        intersection() {
            generateWing();
            generateStructureGrid();
        }
        generateInnerStructureCutout();
        generateSparStructureGap();
        linear_extrude(height = $wing_length, scale = [$tip_chord_ratio, $tip_chord_ratio])
            mcl_poly($wing_chord_length, $naca_airfoil, $center_gap);
    }
}

difference() {
    generateWing();
    generateInnerStructure();
    generateSparStructure();
}
