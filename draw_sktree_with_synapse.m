
function draw_sktree_with_synapse( tree_with_synapse , seg_size_in , output_file_name , tree_ids , dendrite_branchlets )

% tree_with_synapse = xml_sktree_separate_synapse( tree );
% seg_size_in = [2304 3200 384];

global dilate_radius seg_size;
seg_size = seg_size_in;
dilate_radius = 1;

color_code = [ ...
    0, 255, 0;
    0, 0, 255;
    255, 0, 0;    
    255, 0, 255;
];

seg = zeros(seg_size, 'uint32');
annotation_id = 0;

if ~isempty( tree_ids )
    num_trees = numel(tree_ids);
else
    num_trees = numel(tree_with_synapse);
end


for i = 1 : numel( tree_with_synapse )
    
    this_tree = tree_with_synapse{i};
    this_tree_id = this_tree.tree_id; 
    
    if ~isempty( tree_ids )
        if ~ismember( this_tree_id, tree_ids )
            continue;
        end
    end

    annotation_data = [];
    
    % draw non-spine skeleton 
    for j = 1 : numel( this_tree.nodes )
    
        fprintf( 'tree: %d/%d - node: %d/%d\n' , i , num_trees , j , numel(this_tree.nodes) );
        
        this_node = this_tree.nodes(j);
        p1 = uint32( [this_node.voxel_x this_node.voxel_y this_node.voxel_z] );
        
        for k = 1 : numel( this_node.children )
        
            next_node_id = this_node.children(k);
            next_node = this_tree.nodes(next_node_id);
            if next_node.spine 
                continue;
            end

            if exist( 'dendrite_branchlets', 'var' ) && ismember( this_tree_id, [ dendrite_branchlets.tree_id ] )
                idx_branchlet = ([ dendrite_branchlets.tree_id ] == this_tree_id) ;
                nodes_in_branchlets = { dendrite_branchlets( idx_branchlet ).branchlets.nodes };
                seg_idx = find( cellfun( @(x) ismember(next_node_id, x), nodes_in_branchlets ) , 1); 
                branch_seg_id = (i * 10 + 0 ) * 1000 + seg_idx; 
            else
                branch_seg_id = (i * 10 + 0 ); 
            end
            
            p2 = uint32([next_node.voxel_x next_node.voxel_y next_node.voxel_z]);
            [line_segment, min_coord, max_coord] = get_line_segment(p1, p2, branch_seg_id, next_node.spine);
            
            chunk_from_seg = double(seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)));
            chunk_to_seg = line_segment.*(chunk_from_seg==0) + chunk_from_seg; 
            seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)) = uint32(chunk_to_seg);
            
            % - id: %d\n  enabled: false\n  value: {groupID: %d, name: %d, comment: , coord: [%d, %d, %d], color: [%d, %d, %d], linkedAnnotationID: 0}
            annotation_id = annotation_id + 1;
            annotation_name = (this_tree_id * 10 + next_node.spine) * 10000 + next_node_id; 
            annotation_color = color_code( next_node.spine + 1 , : );
            annotation_data = [ annotation_data; uint32( [annotation_id branch_seg_id annotation_name p2 annotation_color] ) ];  %#ok<AGROW>
        end
    
    end
    
    % draw spine skeleton 
    for j=1:numel(this_tree.nodes)
    
        fprintf( 'tree: %d/%d - node: %d/%d\n' , i , num_trees , j , numel(this_tree.nodes) );
        
        this_node = this_tree.nodes(j);
        p1 = uint32([this_node.voxel_x this_node.voxel_y this_node.voxel_z]);
        
        for k=1:numel(this_node.children)
        
            next_node_id = this_node.children(k);
            next_node = this_tree.nodes(next_node_id);
            if ~next_node.spine
                continue;
            end
            
            branch_seg_id = (i * 10 + next_node.spine) * 1000; 
            
            p2 = uint32([next_node.voxel_x next_node.voxel_y next_node.voxel_z]);
            [line_segment, min_coord, max_coord] = get_line_segment(p1, p2, branch_seg_id, next_node.spine);
            
            chunk_from_seg = double(seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)));
            chunk_to_seg = line_segment.*(chunk_from_seg==0) + chunk_from_seg; 
            seg(min_coord(1):max_coord(1), min_coord(2):max_coord(2), min_coord(3):max_coord(3)) = uint32(chunk_to_seg);

            % - id: %d\n  enabled: false\n  value: {groupID: %d, name: %d, comment: , coord: [%d, %d, %d], color: [%d, %d, %d], linkedAnnotationID: 0}
            annotation_id = annotation_id + 1;
            annotation_name = (this_tree_id * 10 + next_node.spine) * 10000 + next_node_id; 
            annotation_color = color_code( next_node.spine + 1 , : );
            annotation_data = [ annotation_data; uint32( [annotation_id branch_seg_id annotation_name p2 annotation_color] ) ];  %#ok<AGROW>
        end
    
    end    

end


fprintf('making omni files ...\n');

output_h5_file_name = sprintf( '%s.h5', output_file_name );
output_omni_file_name = sprintf( '%s.omni', output_file_name );

if exist( output_h5_file_name , 'file' )
    delete( output_h5_file_name );
end
h5create( output_h5_file_name , '/main' , seg_size , 'DataType', 'uint32' , 'ChunkSize' , [128 128 128] );
h5write( output_h5_file_name , '/main' , seg );

fo = fopen( 'omnify.cmd' , 'w' );
fprintf( fo, 'create:%s\n', output_omni_file_name );
fprintf( fo, 'loadHDF5seg:%s\n', output_h5_file_name );
fprintf( fo, 'mesh\n' );
fprintf( fo, 'close\n');
fclose(fo);

system( '/data/omni/omni.omnify/omni.omnify --headless --cmdfile omnify.cmd' );
system( sprintf('find %s* -type d -exec chmod 770 {} +', output_omni_file_name) );
system( sprintf('find %s* -type f -exec chmod 660 {} +', output_omni_file_name) );


% - id: %d\n  enabled: false\n  value: {segID: %d, name: %d, visualize: false, color: [%d, %d, %d]}
group_ids = unique( annotation_data(:, 2) ); 
annotation_colors = color_code ( mod ( group_ids , 10 ) + 1 , : );
annotation_group_data = [ group_ids ones( size(group_ids) ) group_ids annotation_colors ];
    
fo = fopen( 'annotationGroups.yml' ,'w');
fprintf( fo, '---\n' );
fprintf( fo, '- id: %d\n  enabled: true\n  value: {segID: %d, name: %d, visualize: false, color: [%d, %d, %d]}\n', annotation_group_data' );
fprintf( fo, '...' );
fclose( fo );

fo = fopen( 'annotationPoints.yml' ,'w');
fprintf( fo, '---\n' );
fprintf( fo, '- id: %d\n  enabled: false\n  value: {groupID: %d, name: %d, comment: , coord: [%d, %d, %d], color: [%d, %d, %d], linkedAnnotationID: 0}\n', annotation_data' );
fprintf( fo, '...' );
fclose( fo );

system( sprintf('mv annotationPoints.yml annotationGroups.yml %s.files/users/_default/segmentations/segmentation1/', output_omni_file_name) );

fo = fopen( 'settings.yaml', 'w');
fprintf( fo, '---\n' );
fprintf( fo, 'threshold: 0.999\n');
fprintf( fo, 'sizeThreshold: 250\n');
fprintf( fo, 'showAnnotations: true\n');
fprintf( fo, '...' );
fclose( fo );

system( sprintf('mv settings.yaml %s.files/users/_default/', output_omni_file_name) );

end

function [line_segment, min_coord_dilated_corrected, max_coord_dilated_corrected] = get_line_segment(p1, p2, tree_seg_id, spine_idx)

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

if ~spine_idx
    se = strel('sphere', dilate_radius);
    line_segment = tree_seg_id * double(imdilate(dilated_seg, se));
else
    line_segment = tree_seg_id * double(dilated_seg);
end

end

