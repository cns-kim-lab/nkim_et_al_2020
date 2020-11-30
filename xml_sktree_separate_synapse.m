
function tree_with_synapse = xml_sktree_separate_synapse( tree )

tree_with_synapse = tree;

for i = 1 : numel(tree)

    for j = 1 : numel(tree_with_synapse{i}.nodes)
        tree_with_synapse{i}.nodes(j).spine = 0;
    end
    
    end_nodes_with_tag = find( cellfun( @(x) ~isempty(x) , {tree{i}.nodes.tag} ) & cellfun( @(x) isempty(x) , {tree{i}.nodes.children} ) );
    
    for j = 1 : numel(end_nodes_with_tag)
    
        node_id = end_nodes_with_tag(j);
        input_type = [0 0];
        
        for k = 1 : numel( tree{i}.nodes(node_id).tag )
            node_key = tree{i}.nodes(node_id).tag(k).key;
            
            if strcmp( node_key , '1' ) 
                input_type(2) = 1;
            elseif strcmp( node_key , '2' )
                input_type(1) = 1;
            end
        end
        
        if any(input_type)
            [ spine_path , first_branching_ancestor ] = find_first_branching_ancestor( tree{i}.nodes , node_id ); %#ok<ASGLU>
        end
        
        for k = 1 : numel( spine_path )
            tree_with_synapse{i}.nodes(spine_path(k)).spine = sum( input_type .* [2 1] );
        end
        
    end
end

end

function [ spine_path , first_branching_ancestor ] = find_first_branching_ancestor( tree_nodes , starting_node )

spine_path = starting_node;
current_node = starting_node;
parent_node = tree_nodes(current_node).parent;

while numel( tree_nodes(parent_node).children ) <= 1 
    current_node = parent_node;
    parent_node = tree_nodes(parent_node).parent; 
    spine_path = [ spine_path , current_node ];  %#ok<AGROW>    
end

first_branching_ancestor = parent_node;

end
