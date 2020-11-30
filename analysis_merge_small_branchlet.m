
function [ dendrite_branchlets , branchlet_metadata ] = analysis_merge_small_branchlet( tree_with_synapse , dendrite_branchlets , branchlet_metadata, length_threshold )

% branchlet_metadata = analysis_get_branchlet_metadata( tree_with_synapse , dendrite_branchlets ); 

if length_threshold == 0 
    return;
end

for i = 1 : numel( dendrite_branchlets )
    
    if isempty(dendrite_branchlets{i})
        continue;
    end
    
    fprintf( 'tree: %d \n' , i );
    
    this_tree_id = i;
    this_branchlets = dendrite_branchlets{this_tree_id};
    for j = 1 : numel( tree_with_synapse )
        if tree_with_synapse{j}.tree_id == this_tree_id
            this_tree = tree_with_synapse{j};
            break;
        end
    end
    
    for j = 1 : numel( this_branchlets )

        nodes = this_branchlets{j};
        
        nodes_start = nodes( 1 : end-1 ); 
        nodes_end   = nodes( 2 : end );
        
        X1 = [ [this_tree.nodes(nodes_start).x]' , [this_tree.nodes(nodes_start).y]' , [this_tree.nodes(nodes_start).z]' ];
        X2 = [ [this_tree.nodes(nodes_end).x]'   , [this_tree.nodes(nodes_end).y]'   , [this_tree.nodes(nodes_end).z]' ];
        X = X1 - X2; 
        
        this_path_length = sum( sqrt( sum( X.*X , 2) ) );
        
    end

    
end

end
