
function seg = put_sk_annotation_to_omni(tree)

% tree = parse_trakem2_xml_to_sktree(s);
% seg = hdf5read(seg_file);


% for i=1:numel(tree)
for i=1:1

    this_tree = tree{i};
    this_tree_id = this_tree.tree_id; 
    
    for j=1:numel(this_tree.nodes)
        
        this_node = this_tree.nodes(j);
        p1 = uint32([this_node.x this_node.y this_node.z]);
        
        for k=1:numel(this_node.children)
        
            next_node_id = this_node.children(k);
            next_node = this_tree.nodes(next_node_id);
            p2 = uint32([next_node.x next_node.y next_node.z]);

            line_segment = get_line_segment(p1, p2, this_tree_id);
            min_coord = min(p1, p2);
            max_coord = max(p1, p2);
            
            chunk_from_seg = double(seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)));
            chunk_to_seg = line_segment + chunk_from_seg.*(line_segment==0); 
            seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)) = uint32(chunk_to_seg);

        end
    
    end
    

end

end

function line_segment = get_line_segment(p1, p2, tree_id)

% transform to coord inside the bounding box
min_coord = min(p1, p2);
max_coord = max(p1, p2);
bounding_box_size = max_coord - min_coord + 1;
bounding_box_seg = zeros(bounding_box_size,'logical');

p1 = double(p1 - min_coord + 1);
p2 = double(p2 - min_coord + 1);

dist = norm( p2 - p1 );
t = [0:1/(2*dist):0.99999 1];
loc_sub = (repmat(p1,length(t),1)'+(p2-p1)'*t)'; 
loc_sub = unique(uint32(loc_sub), 'rows');
loc_ind = sub2ind(bounding_box_size, loc_sub(:,1), loc_sub(:,2), loc_sub(:,3));
bounding_box_seg(loc_ind) = 1;

se = strel('sphere', 2);
line_segment = tree_id * double(imdilate(bounding_box_seg, se));

end
