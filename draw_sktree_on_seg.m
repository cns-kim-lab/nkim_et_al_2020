
function seg = draw_sktree_on_seg(tree, seg)

% tree = parse_trakem2_xml_to_sktree(s);
% seg = hdf5read(seg_file);

global dilate_radius seg_size;

seg_size = uint32(size(seg));
dilate_radius = 1;

for i=1:numel(tree)

    this_tree = tree{i};
    this_tree_id = this_tree.tree_id; 
    
    for j=1:numel(this_tree.nodes)
        
        this_node = this_tree.nodes(j);
        p1 = uint32([this_node.x this_node.y this_node.z]);
        
        tree_seg_id = this_tree_id * 1000 + ceil(j/20); 
        
        for k=1:numel(this_node.children)
        
            next_node_id = this_node.children(k);
            next_node = this_tree.nodes(next_node_id);
            p2 = uint32([next_node.x next_node.y next_node.z]);

            [line_segment, min_coord, max_coord] = get_line_segment(p1, p2, tree_seg_id);
            
            chunk_from_seg = double(seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)));
            chunk_to_seg = line_segment + chunk_from_seg.*(line_segment==0); 
            seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)) = uint32(chunk_to_seg);

        end
    
    end

end

end

function [line_segment, min_coord_dilated_corrected, max_coord_dilated_corrected] = get_line_segment(p1, p2, tree_seg_id)

global dilate_radius seg_size;

% transform to coord inside the bounding box
min_coord = min(p1, p2);
max_coord = max(p1, p2);

bounding_box_size = max_coord - min_coord + 1;
bounding_box_seg = zeros(bounding_box_size,'logical');

p1_loc = double(p1 - min_coord + 1);
p2_loc = double(p2 - min_coord + 1);

% line from p1 to p2
dist = norm( p2_loc - p1_loc );
t = [0:1/(2*dist):0.99999 1];
loc_sub = (repmat(p1_loc,length(t),1)'+(p2_loc-p1_loc)'*t)'; 
loc_sub = unique(uint32(loc_sub), 'rows');
loc_ind = sub2ind(bounding_box_size, loc_sub(:,1), loc_sub(:,2), loc_sub(:,3));
bounding_box_seg(loc_ind) = 1;

% to get dilated line, prepare dilatebox considering the seg_size
min_coord_dilated = min_coord - dilate_radius;
dim_correction_min = min_coord_dilated < 1; 
min_coord_dilated_corrected = min_coord_dilated;
min_coord_dilated_corrected(dim_correction_min) = 1;

max_coord_dilated = max_coord + dilate_radius; 
dim_correction_max = max_coord_dilated > seg_size;
max_coord_dilated_corrected = max_coord_dilated; 
max_coord_dilated_corrected(dim_correction_max) = seg_size(dim_correction_max);

dilated_seg_size = max_coord_dilated_corrected - min_coord_dilated_corrected + 1;
dilated_seg = zeros(dilated_seg_size,'logical');

min_coord_loc = uint32(repmat(dilate_radius + 1, 1, 3));
min_coord_loc = min_coord_loc - (min_coord_dilated_corrected - min_coord_dilated);
max_coord_loc = min_coord_loc + bounding_box_size - 1; 

dilated_seg(min_coord_loc(1):max_coord_loc(1), min_coord_loc(2):max_coord_loc(2), min_coord_loc(3):max_coord_loc(3)) = bounding_box_seg;

se = strel('sphere', dilate_radius);
line_segment = tree_seg_id * double(imdilate(dilated_seg, se));

end
