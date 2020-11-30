
function tree_with_projected_synapse_and_distance = analysis_get_distance_from_root( tree_with_projected_synapse )

tree_with_projected_synapse_and_distance = tree_with_projected_synapse; 

for i = 1 : numel( tree_with_projected_synapse )
    
    this_tree = tree_with_projected_synapse{i};
    this_tree_id = this_tree.tree_id; 
    
    fprintf( 'tree %d: %d\n' , i , this_tree_id );

    
    root_node = find( [this_tree.nodes.parent] == 0 );
    tree_with_projected_synapse_and_distance{i}.nodes(root_node).root_distance = 0;
    current_nodes = root_node;

    while ~isempty( current_nodes )
        
        next_current_nodes = [];
        
        for j = 1 : numel( current_nodes )
        
            one_current_node = current_nodes(j);
            next_nodes = this_tree.nodes(one_current_node).children;
            current_root_distance = tree_with_projected_synapse_and_distance{i}.nodes(one_current_node).root_distance;
            
            for k = 1 : numel( next_nodes )

                one_next_node = next_nodes(k);

                X1 = [ this_tree.nodes(one_current_node).physical_x , this_tree.nodes(one_current_node).physical_y , this_tree.nodes(one_current_node).physical_z ];
                X2 = [ this_tree.nodes(one_next_node).physical_x , this_tree.nodes(one_next_node).physical_y, this_tree.nodes(one_next_node).physical_z ];
                distance_to_one_next_node = norm( X1 - X2 );

                tree_with_projected_synapse_and_distance{i}.nodes(one_next_node).root_distance = current_root_distance + distance_to_one_next_node; 

            end
            
            next_current_nodes = [ next_current_nodes, next_nodes ]; %#ok<AGROW>
        
        end
        
        current_nodes = next_current_nodes; 
        
    end
    
end

end
