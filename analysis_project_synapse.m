
function synapse_projected_tree = analysis_project_synapse( tree_with_synapse , dendrite_branchlets )

% dendrite_branchlets = analysis_split_dendrite_branchlets( tree_with_synapse , [] );


for i = 1 : numel( tree_with_synapse )

    fprintf( 'tree: %d \n' , this_tree_id );
    
    this_tree_id = this_tree.tree_id; 
    this_tree_branchlets = dendrite_branchlets{this_tree_id};
    
    this_tree = tree_with_synapse{i};
    this_tree_shaft = tree_with_synapse{i};

        
    % only for non-spine dendritic skeleton nodes: prune spines 
    is_spine_node = logical([this_tree.nodes.spine]);
    for j = 1 : numel(this_tree.nodes)
        nodes_to_del = is_spine_node( this_tree.nodes(j).children ); 
        if ~isempty( nodes_to_del )
            this_tree_shaft.nodes(j).children( nodes_to_del ) = [];
        end
    end

    
    
end


end