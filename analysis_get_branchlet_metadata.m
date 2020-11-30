
function dendrite_branchlets = analysis_get_branchlet_metadata( tree_with_synapse , dendrite_branchlets )

for i = 1 : numel( dendrite_branchlets )
    
    if isempty(dendrite_branchlets(i))
        continue;
    end
    
    end_nodes_in_this_tree = find( cellfun( @(x) x==0 , {tree_with_synapse{i}.nodes.spine} ) & cellfun( @(x) isempty(x) , {tree_with_synapse{i}.nodes.children} ) );
    
    this_tree_id = dendrite_branchlets(i).tree_id;
    this_tree = tree_with_synapse{i}; 
    fprintf( 'tree: %d \n' , this_tree_id );
    
    this_tree_branchlets = dendrite_branchlets(i).branchlets;
    for j = 1 : numel( this_tree_branchlets )

        nodes = this_tree_branchlets(j).nodes;
        
        % branchlet length
        nodes_start = nodes( 1 : end-1 ); 
        nodes_end   = nodes( 2 : end );
        
        X1 = [ [this_tree.nodes(nodes_start).physical_x]' , [this_tree.nodes(nodes_start).physical_y]' , [this_tree.nodes(nodes_start).physical_z]' ];
        X2 = [ [this_tree.nodes(nodes_end).physical_x]'   , [this_tree.nodes(nodes_end).physical_y]'   , [this_tree.nodes(nodes_end).physical_z]' ];
        X = X1 - X2; 
        
        this_path_length = sum( sqrt( sum( X.*X , 2) ) );
        dendrite_branchlets(i).branchlets(j).path_length = this_path_length;
        
        % branchlet type: is terminal
        if isempty( intersect( nodes , end_nodes_in_this_tree ) ) % not terminal
            dendrite_branchlets(i).branchlets(j).is_terminal = 0;
        else
            dendrite_branchlets(i).branchlets(j).is_terminal = 1;
        end        
        
        % num synapses by type
        if ~isempty(dendrite_branchlets(i).branchlets(j).spines)
            dendrite_branchlets(i).branchlets(j).num_input1 = sum( [dendrite_branchlets(i).branchlets(j).spines.type] == 1 ); 
            dendrite_branchlets(i).branchlets(j).num_input2 = sum( [dendrite_branchlets(i).branchlets(j).spines.type] == 2 ); 
        else
            dendrite_branchlets(i).branchlets(j).num_input1 = 0;
            dendrite_branchlets(i).branchlets(j).num_input2 = 0;
        end
    end
    
    dendrite_branchlets(i).num_input1 = sum([dendrite_branchlets(i).branchlets.num_input1]);
    dendrite_branchlets(i).num_input2 = sum([dendrite_branchlets(i).branchlets.num_input2]);
end


end
